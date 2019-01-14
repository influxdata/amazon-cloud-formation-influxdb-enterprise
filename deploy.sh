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
VPC_ID="vpc-46ae0a3c"
SUBNETS="subnet-0a4add24\\,subnet-2a7bee76\\,subnet-2f4ec648\\,subnet-28a7ff62\\,subnet-ec4a96d2\\,subnet-2c99db23"

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
