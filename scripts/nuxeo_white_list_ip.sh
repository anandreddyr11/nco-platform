#!/bin/bash -e

set -ex

################################################################################
# File:    nuxeo_white_list_ip.sh
# Purpose: This Script use for whitelist the ip
# Version: 0.1
# Author:  Ravi Prajapati
# Created: 2017-09-27
# Usage: nuxeo_white_list_ip 22 "ip1,ip2" v1.2.0
################################################################################


PORT=$1
IP=$2
INFRASTRUCTUR_VERSION=$3

if [[ -z "${PORT}" ]] || [[ -z "${IP}" ]] || [[ -z "${INFRASTRUCTUR_VERSION}" ]];then
echo "Parameter is missing"
exit 1
fi

VPC_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:aws:autoscaling:groupName,Values=${STACK_NAME}-${ENVIRONMENT}-nuxeo*" "Name=tag:service,Values=nuxeo" "Name=tag:infrastructure-version,Values=${INFRASTRUCTUR_VERSION}"  --region ${AWS_REGION} --output text  --query "Reservations[0].Instances[0].VpcId" )

if [[ "${VPC_ID}" == "None" ]];then
      echo "Unable to get VPC" 
      exit 1
fi

echo "Bastion VPC ID : $VPC_ID"

SECURITY_GROUP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=vpc-id,Values=${VPC_ID}"   "Name=tag:service,Values=bastion" "Name=tag:stack-identifier,Values=${STACK_NAME}" "Name=tag:infrastructure-version,Values=${INFRASTRUCTUR_VERSION}"   --region $AWS_REGION |  jq -r .Reservations[].Instances[].SecurityGroups[0].GroupId)

echo "Bastion SECURITY_GROUP : $SECURITY_GROUP"

aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP} --protocol tcp --port ${PORT} --cidr "${IP}/32" --region ${AWS_REGION}