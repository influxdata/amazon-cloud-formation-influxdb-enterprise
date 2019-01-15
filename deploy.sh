#!/usr/bin/env bash

STACK_NAME=$1

TEMPLATE_BODY="file://influxdb-enterprise-byol.template"
REGION=`aws configure get region`

LICENSE_KEY="${LICENSE_KEY}"
USERNAME="admin"
PASSWORD="admin"
KEY_NAME="influxdb-${REGION}"
SSH_LOCATION="0.0.0.0/0"
VPC_ID="$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[].VpcId" --output text)"
# SUBNETS="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[].SubnetId" --output text | tr '\t' '\,')"
SUBNETS="subnet-28a7ff62\\,subnet-2a7bee76\\,subnet-ec4a96d2\\,subnet-2f4ec648\\,subnet-0a4add24\\,subnet-2c99db23"

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
ParameterKey=KeyName,ParameterValue=${KEY_NAME} \
ParameterKey=SSHLocation,ParameterValue=${SSH_LOCATION}
