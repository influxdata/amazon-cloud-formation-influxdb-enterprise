#!/usr/bin/env bash

set -euxo pipefail


function get_node_hostname {
  echo -n "$(curl --location --silent --fail --show-error http://169.254.169.254/latest/meta-data/hostname)"
}

function mount_volumes {
  local -r device_name="/dev/xvdh"
  local -r mount_point="/mnt/influxdb"

  echo "Creating filesystem and mount point"
  mkfs -t ext4 "${device_name}"
  mkdir "${mountpoint}"

  echo "Updating fstab"
  echo -e "${device_name}\t${mount_point}\text4\tdefaults,nofail\t0\t2" >> /etc/fstab

  echo "Mounting volume"
  mount -a

  echo "Creating directories for InfluxDB data (meta, data, wal, & hh)"
  mkdir "${mount_point}/meta" "${mount_point}/data" "${mount_point}/wal" "${mount_point}/hh"

  echo "Changing permissions of mount point"
  sudo chown -R influxdb:influxdb "${mount_point}"
}

function wait_for_asg_instances() {
  local -r region="$1"
  local -r asg_name="$2"
  local -r timeout_sec="${3:-600}"
  local current_time=$(date +%s)
  local -r timeout_time_sec=$(("${current_time}" + "${timeout_sec}"))
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
  local -r aws_region="$1"
  local -r meta_asg_name="$2"
  local -r data_asg_name="$3"
  local -r meta_hosts=$(aws ec2 describe-instances --region "${aws_region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${meta_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].[PrivateIpAddress, PrivateDnsName]' --output text)
  local -r data_hosts=$(aws ec2 describe-instances --region "${aws_region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${data_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].[PrivateIpAddress, PrivateDnsName]' --output text)

  echo "${meta_hosts}" | sudo tee -a /etc/hosts > /dev/null
  echo "${data_hosts}" | sudo tee -a /etc/hosts > /dev/null
}

function init_cluster {
  local -r region="$1"
  local -r meta_leader="$2"
  local -r meta_asg_name="$3"
  local -r data_asg_name="$4"
  local -r meta_hosts=$(aws ec2 describe-instances --region "${aws_region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${meta_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].PrivateDnsName' --output text)
  local -r data_hosts=$(aws ec2 describe-instances --region "${aws_region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${data_asg_name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [].PrivateDnsName' --output text)

  for instance in ${meta_hosts}; do
    influxd-ctl add-meta "${instance}:8091"
    echo -n "$?"
  done

  for instance in ${data_hosts}; do
    influxd-ctl add-data "${instance}:8088"
    echo -n "$?"
  done
}

function run {
  local -r aws_region="$1"
  local -r license_key="$2"
  local -r node_type="$5"
  local -r username="$3"
  local -r password="$4"
  local -r hostname="${HOSTNAME}"

  echo "Mounting EBS Volume for meta, data, wal and hh directories"
  mount_volumes

  echo "Filling out InfluxDB template"
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

  echo "Waiting for all instances in auto scaling groups"
  wait_for_asg_instances "${aws_region}" "${data_asg_name}"
  wait_for_asg_instances "${aws_region}" "${meta_asg_name}"

  echo "Setting hostnames for other instances"
  set_instance_hostnames "${aws_region}" "${meta_asg_name}" "${data_asg_name}" 

  echo "Checking if instance is the first meta node created"
  local meta_leader=$(aws ec2 describe-instances --region "${aws_region}" --filters "Name=tag:aws:autoscaling:groupName,Values=${meta_asg_name}" "Name=instance-state-name,Values=pending,running" --query 'Reservations[].Instances[] | sort_by(@, &LaunchTime)[] | [0].PrivateDnsName')
  if [ "${hostname}" != "${meta_leader}" ]; then
    echo "Initiating cluster on meta node leader"
    init_cluster "${aws_region}" "${meta_leader}" "${meta_asg_name}" "${data_asg_name}"

    echo "Creating initial cluster admin"
    create_influxdb_user "${username}" "${password}"
  fi

  echo "Setup succeeded!"
}
