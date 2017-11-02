#!/bin/bash
set -e

# USAGE: 
# freeCIDR.sh REGION CUSTOMER
# example: freeCIDR.sh us-east-1 nuxeo dev 

cond_var=""
cidr=""

REGION=$1
CUSTOMER=$2
CLOUD_NAME="${CUSTOMER}"


COUNTER=0
exist_cidr=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=$CLOUD_NAME" "Name=tag:managed_by,Values=terraform" --output text --query "Vpcs[0].CidrBlock" )
if [ "$exist_cidr" != "None" ]
   then
      echo "$exist_cidr" 
      exit 0
fi

while [ "$cond_var" != "done" ]
do
     cidr="10.$COUNTER.0.0/20"
         output=$(aws ec2 describe-vpcs --region $REGION --filters "Name=cidr,Values=$cidr" --output text --query "Vpcs[0].CidrBlock" )
     if [ "$output" = "None" ]
      then
              cond_var="done"
     fi
     COUNTER=$[$COUNTER +1]     
done

echo "$cidr"