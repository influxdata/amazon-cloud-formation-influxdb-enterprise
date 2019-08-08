#!/usr/bin/env bash

set -euxo pipefail

# This is an development script for creating an InfluxDB Enterprise stack using
# the Cloud Formation template in this repository. Please replace the InfluxDB password

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

# By default, this script will not actually execute a deploy. Remove the
# "--no-execute-changeset" option to create resources.

readonly stack_name="${1}"
readonly influxdb_username="${2:-admin}"
readonly influxdb_password="${3:-admin}"
readonly license_key="${LICENSE_KEY}"

readonly template="cf-templates/influxdb-enterprise-byol.json"
readonly vpc="$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[].VpcId" --output text)"
readonly subnets="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" | jq -r '.[0:3] | @tsv')"
readonly availability_zones="$(aws ec2 describe-subnets --subnet-ids $subnets --query "Subnets[].AvailabilityZone" | jq -r '.[0:3] | @tsv' | sed -e $'s/\t/,/g')"
readonly ssh_key_name="influxdb-$(aws configure get region)"

IFS=$'\n' aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --template-file "${template}" \
    --s3-bucket "aws-marketplace-influxdata" \
    --stack-name "${stack_name}" \
    --parameter-overrides \
        VpcId="${vpc}" \
        Subnets="$(echo "${subnets}" | sed -e $'s/\t/,/g')" \
        AvailabilityZones="$(echo "${availability_zones}" | sed -e $'s/\t/,/g')" \
        Username="${influxdb_username}" \
        Password="${influxdb_password}" \
        KeyName="${ssh_key_name}" \
        InfluxDBIngressCIDR="${ssh_location}" \
        SSHLocation="${ssh_location}" \
        LicenseKey="${license_key}"
