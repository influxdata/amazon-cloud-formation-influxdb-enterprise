#!/usr/bin/env bash

set -euxo pipefail


function get_hostname {
  echo -n "$(curl --location --silent --fail --show-error http://169.254.169.254/latest/meta-data/hostname)"
}

function get_asg_name {
  local -r stack_name="$1"
  local -r region="$2"
  local -r node_type="$3"

  echo -n "$(aws autoscaling describe-auto-scaling-groups \
    --region "${region}" \
    --query "AutoScalingGroups[?Tags[?Key=='aws:cloudformation:stack-name'&&Value=='${stack_name}']].AutoScalingGroupName[? contains(@, '${node_type}')]" \
    --output text)"
}

function get_asg_hosts {
  local -r region="$1"
  local -r asg_name="$2"

  echo -n "$(aws ec2 describe-instances \
    --region "${region}" \
    --filters "Name=tag:aws:autoscaling:groupName,Values=${asg_name}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].[PrivateIpAddress, PrivateDnsName]' \
    --output text)"
}

function get_meta_leader {
  local -r region="$1"
  local -r meta_asg_name="$2"

  echo -n "$(aws ec2 describe-instances \
    --region "${region}" \
    --filters "Name=tag:aws:autoscaling:groupName,Values=${meta_asg_name}" "Name=instance-state-name,Values=pending,running" \
    --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [0].PrivateDnsName' \
    --output text)"
}

function wait_for_asg_instances() {
  local -r region="$1"
  local -r asg_name="$2"
  local -r timeout_sec="${3:-600}"
  local current_time=$(date +%s)
  local -r timeout_time_sec=$((${current_time} + ${timeout_sec}))
  local -r asg_target_size=$(aws autoscaling describe-auto-scaling-groups --region "${region}" --auto-scaling-group-names "${asg_name}" --query 'AutoScalingGroups[0].DesiredCapacity')
  local asg_instance_count=$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId | length(@)')
  
  while [[ "${asg_instance_count}" != "${asg_target_size}" ]] \
        && [[ $(date +%s) -lt ${timeout_time_sec} ]]; do
      echo "Waiting for all instances in auto scaling group. Trying in 30s..."
      sleep 30
      local asg_instance_count=$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId | length(@)')
  done
  echo ""
}

function set_instance_hostnames {
  local -r region="$1"
  local -r meta_asg_hosts="$2"
  local -r data_asg_hosts="$3"

  echo "${meta_asg_hosts}" | sudo tee -a /etc/hosts > /dev/null
  echo "${data_asg_hosts}" | sudo tee -a /etc/hosts > /dev/null
}

function init_cluster {
  local -r region="$1"
  local -r meta_leader="$2"
  local -r meta_asg_hosts="$3"
  local -r data_asg_hosts="$4"

  for host in $(echo "${meta_asg_hosts}" | cut -f2); do
    influxd-ctl add-meta "${host}:8091"
    echo -n "$?"
  done

  for host in $(echo "${data_asg_hosts}" | cut -f2); do
    influxd-ctl add-data "${host}:8088"
    echo -n "$?"
  done
}

function create_influxdb_user {
  local -r data_asg_hosts="$1"
  local -r username="$2"
  local -r password="$3"

  influx -host "$(echo "${data_asg_hosts}" | head -n 1 | cut -f2)" -execute "CREATE USER ${username} WITH PASSWORD '${password}' WITH ALL PRIVILEGES"
}

function run {
  local -r stack_name="$1"
  local -r region="$2"
  local -r license_key="$3"
  local -r node_type="$4"
  local -r username="$5"
  local -r password="$6"
  local -r hostname="${HOSTNAME}"

  local -r meta_asg_name="$(get_asg_name "${stack_name}" "${region}" "Meta")"
  local -r data_asg_name="$(get_asg_name "${stack_name}" "${region}" "Data")"

  echo "Waiting for all instances in auto scaling groups"
  wait_for_asg_instances "${region}" "${meta_asg_name}"
  wait_for_asg_instances "${region}" "${data_asg_name}"

  local -r meta_asg_hosts="$(get_asg_hosts "${region}" "${meta_asg_name}")"
  local -r data_asg_hosts="$(get_asg_hosts "${region}" "${data_asg_name}")"

  echo "Setting hostnames for other instances"
  set_instance_hostnames "${region}" "${meta_asg_hosts}" "${data_asg_hosts}" 

  echo "Checking if instance is the first meta node created"
  local -r meta_leader=$(get_meta_leader "${region}" "${meta_asg_name}")
  if [ "${hostname}" == "${meta_leader}" ]; then
    echo "Initiating cluster on meta node leader"
    init_cluster "${region}" "${meta_leader}" "${meta_asg_hosts}" "${data_asg_hosts}"

    echo "Creating initial InfluxDB Enterprise admin user"
    create_influxdb_user "${data_asg_hosts}" "${username}" "${password}"
  fi

  echo "InfluxDB Enterprise setup succeeded!"
}