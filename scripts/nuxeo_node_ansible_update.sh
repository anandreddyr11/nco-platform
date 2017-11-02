#!/bin/bash -e

set -ex

################################################################################
# File:    nuxeo_node_ansible_update
# Purpose: This Script use run ansible stuff
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-08-24
# Usage: bash nuxeo_node_ansible_update -h
################################################################################

ssh_key=/root/.ssh/platform
NCO_VERSION_RELEASE=${NCO_VERSION}

usage()
{
    echo -e "This script use for resrore backup from s3"
    echo -e "-e  Environment"
    echo -e "-c  Customer name"
    echo -e "-s  StackName "
    echo -e "-r  Ansible role"
    echo -e "-n  Node type, app,es,bastion,worker"
    echo -e "-a  Aws Region"
    echo -e "-R  Nuxeo NCO Release, v1.1.1,v1.2.1"
    echo -e "-h  help  ${NORM}"
    exit 1
}


####################################################
###############  PARSE ARGUMENTS ###################
####################################################

while getopts "h:e:c:s:r:n:a:R:" opt; do

  case $opt in
    h)
      usage
      ;;
    e)
      ENVIRONMENT="$OPTARG"
      ;;        
    c)
      CUSTOMER="$OPTARG"
      ;;
    s)
      STACK_NAME="$OPTARG"
      ;;
    r)
      ROLE="$OPTARG"
      ;;        
    R)
      NCO_VERSION_RELEASE="$OPTARG"
      ;;          
    n)
      NODE_TYPE="$OPTARG"
      ;;
    a)
      AWS_REGION="$OPTARG"
      ;; 
    \?)
      usage
      ;;
  esac

done


VPC_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:aws:autoscaling:groupName,Values=${STACK_NAME}-${ENVIRONMENT}-nuxeo*" "Name=tag:service,Values=nuxeo" "Name=tag:project,Values=${CUSTOMER}"  --region ${AWS_REGION} --output text  --query "Reservations[0].Instances[0].VpcId" )

if [[ "${VPC_ID}" == "None" ]];then
      echo "Unable to get VPC" 
      exit 1
fi

echo "Bastion VPC ID : $VPC_ID"

BASTION_IP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=vpc-id,Values=${VPC_ID}"   "Name=tag:service,Values=bastion" "Name=tag:stack-identifier,Values=${STACK_NAME}" "Name=tag:project,Values=${CUSTOMER}"   --region $AWS_REGION | jq -r .Reservations[].Instances[].PublicIpAddress)

echo "Bastion Ip : $BASTION_IP"

ssh -ttq -i $ssh_key root@$BASTION_IP "bash /usr/local/nuxeo-backup/nuxeo_ansible_update -e $ENVIRONMENT -c $CUSTOMER -s $STACK_NAME -r ${ROLE} -n $NODE_TYPE -v $VPC_ID -R $NCO_VERSION_RELEASE" 2> /dev/null