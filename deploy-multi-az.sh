#!/usr/bin/env bash

set -euxo pipefail

# This is an development script for creating an InfluxDB Enterprise stack using
# the Cloud Formation template in this repository. Please replace the InfluxDB password

# Required resources: VPC with 3 subnets, EC2 key pair, S3 bucket

# This script works for MacOS. To run on linux, swap the ssh_location command to
# 'hostname --ip-address' or "0.0.0.0/0"
ssh_location="unknown"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    ssh_location="$(hostname --ip-address)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ssh_location="$(dig @resolver1.opendns.com ANY myip.opendns.com +short)/32"
else
    echo -n "WARNING: cannot determine local IP address"
    ssh_location="0.0.0.0/0"
fi

readonly stack_name="${1}"
readonly region="${2:-$(aws configure get region)}"
readonly influxdb_username="${3:-admin}"
readonly influxdb_password="${4:-admin}"
readonly license_key="${LICENSE_KEY}"

readonly template="cf-templates/byol-multi-az.json"
readonly ssh_key_name="$(aws ec2 describe-key-pairs --query "KeyPairs[?starts_with(KeyName, 'influxdb')].KeyName" --output text --region "$region")"
readonly vpc_class_b="0"

# By default, this script will not actually execute a deploy. Remove the
# "--no-execute-changeset" option to create resources.

IFS=$'\n' aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --template-file "${template}" \
    --s3-bucket "aws-marketplace-influxdata-${region}" \
    --stack-name "${stack_name}" \
    --region "${region}" \
    --parameter-overrides \
        VpcClassB="${vpc_class_b}" \
        Username="${influxdb_username}" \
        Password="${influxdb_password}" \
        KeyName="${ssh_key_name}" \
        InfluxDBIngressCIDR="${ssh_location}" \
        SSHLocation="${ssh_location}" \
        LicenseKey="${license_key}"
