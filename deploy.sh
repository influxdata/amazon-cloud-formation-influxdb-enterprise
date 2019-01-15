#!/usr/bin/env bash

STACK_NAME=$1

TEMPLATE_BODY="file://influxdb-enterprise-byol.template"
REGION=`aws configure get region`

LICENSE_KEY="${LICENSE_KEY}"
USERNAME="admin"
PASSWORD="admin"
INFLUX_VERSION=1.7.2
KEY_NAME="influxdb-${REGION}"
SSH_LOCATION="0.0.0.0/0"
VPC_ID="$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[].VpcId" --output text)"
SUBNETS="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[].SubnetId")"

aws cloudformation create-stack \
--capabilities CAPABILITY_IAM \
--template-body ${TEMPLATE_BODY} \
--stack-name ${STACK_NAME} \
--region ${REGION} \
--on-failure DELETE \
--parameters \
ParameterKey=VpcId,ParameterValue=${VPC_ID} \
ParameterKey=Subnets,ParameterValue=${SUBNETS} \
ParameterKey=LicenseKey,ParameterValue=${LICENSE_KEY} \
ParameterKey=Username,ParameterValue=${USERNAME} \
ParameterKey=Password,ParameterValue=${PASSWORD} \
ParameterKey=InfluxDBEnterprsieVersion,ParameterValue=${INFLUX_VERSION} \
ParameterKey=KeyName,ParameterValue=${KEY_NAME} \
ParameterKey=SSHLocation,ParameterValue=${SSH_LOCATION}
