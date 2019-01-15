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
  local -r asg_name="$1"

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

function mount_volumes {
  local -r device_name="/dev/xvdh"
  local -r mount_point="/mnt/influxdb"

  echo "Creating filesystem and mount point"
  sudo mkfs -t ext4 "${device_name}"
  sudo mkdir "${mount_point}"

  echo "Updating fstab"
  echo -e "${device_name}\t${mount_point}\text4\tdefaults,nofail\t0\t2" | sudo tee -a /etc/fstab > /dev/null

  echo "Mounting volume"
  sudo mount -a

  echo "Creating directories for InfluxDB data (meta, data, wal, & hh)"
  sudo mkdir "${mount_point}/meta" "${mount_point}/data" "${mount_point}/wal" "${mount_point}/hh"

  echo "Changing permissions of mount point"
  sudo chown -R influxdb:influxdb "${mount_point}"
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
  local -r meta_hosts=$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${meta_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].PrivateDnsName' --output text)
  local -r data_hosts=$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${data_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].PrivateDnsName' --output text)

  for host in $(echo "${meta_asg_hosts}" | cut -f2); do
    influxd-ctl add-meta "${host}:8091"
    echo -n "$?"
  done

  for host in $(echo "${meta_asg_hosts}" | cut -f2); do
    influxd-ctl add-data "${host}:8088"
    echo -n "$?"
  done
}

function create_influxdb_user {
  local -r data_asg_hosts="$1"
  local -r username="$2"
  local -r password="$3"

  influx -host $(echo "${data_asg_hosts[0]}" | cut -f2) -execute "CREATE USER ${username} WITH PASSWORD '${password}' WITH ALL PRIVILEGES"
}

function run {
  local -r stack_name="$1"
  local -r region="$2"
  local -r license_key="$3"
  local -r node_type="$4"
  local -r username="$5"
  local -r password="$6"
  local -r hostname="${HOSTNAME}"

  echo "Mounting EBS Volume for meta, data, wal and hh directories"
  mount_volumes

  echo "Filling out InfluxDB config template"
  sudo sed -i "s|PLACEHOLDER_LICENSE_KEY|${license_key}|" /etc/influxdb/influxdb-meta.conf > /dev/null
  sudo sed -i "s|PLACEHOLDER_HOSTNAME|${hostname}|" /etc/influxdb/influxdb-meta.conf > /dev/null
  sudo sed -i "s|PLACEHOLDER_LICENSE_KEY|${license_key}|" /etc/influxdb/influxdb.conf > /dev/null
  sudo sed -i "s|PLACEHOLDER_HOSTNAME|${hostname}|" /etc/influxdb/influxdb.conf > /dev/null

  echo "Starting InfluxDB Enterprise service"
  if [ "${node_type}" == "meta" ]; then
    sudo systemctl enable influxdb-meta.service
    sudo systemctl start influxdb-meta.service
  else
    sudo systemctl enable influxdb.service
    sudo systemctl start influxdb.service
  fi
  sleep 10

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
