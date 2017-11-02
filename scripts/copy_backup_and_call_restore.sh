#!/bin/bash -e

set -ex

################################################################################
# File:    copy_backup_and_call_restore
# Purpose: This Script use for restore backup from another account
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-06-14
# Usage: bash copy_backup_and_call_restore -h
################################################################################


RESTORE_DB=false
RESTORE_ES_INDEX=false
RESTORE_ES_BINARIES=false
ssh_key=/root/.ssh/platform

usage()
{
    echo -e "This script use for resrore backup from s3"
    echo -e "-d  DB Restore full s3 path"
    echo -e "-e  Elasticsearch index full s3 path"
    echo -e "-b  Elasticsearch binaries full s3 path"
    echo -e "-D  Restore Database, default false"
    echo -e "-E  Restore Elasticsearch index, default false"
    echo -e "-B  Restore Elasticsearch binaries, default false"
    echo -e "-h  help  ${NORM}"
    exit 1
}


####################################################
###############  PARSE ARGUMENTS ###################
####################################################

while getopts "h:d:e:b:D:E:B:" opt; do

  case $opt in
    h)
      usage
      ;;
    d)
      DB_SOURCE_FULL_PATH="$OPTARG"
      ;;        
    e)
      ES_INDEX_SOURCE_FULL_PATH="$OPTARG"
      ;;
    b)
      ES_BINARIES_SOURCE_FULL_PATH="$OPTARG"
      ;;
    D)
      RESTORE_DB=$OPTARG
      ;;        
    E)
      RESTORE_ES_INDEX=$OPTARG
      ;;
    B)
      RESTORE_ES_BINARIES=$OPTARG
      ;;    
    \?)
      usage
      ;;
  esac

done


if [[ "$RESTORE_DB" = true ]] && [[ -z "$DB_SOURCE_FULL_PATH" ]];then
 echo "DB_SOURCE_FULL_PATH is empty, Please pass DB_SOURCE_FULL_PATH"
 exit 0
elif [[ "$RESTORE_ES_INDEX" = true ]] && [[ -z "$ES_INDEX_SOURCE_FULL_PATH" ]];then
 echo "ES_INDEX_SOURCE_FULL_PATH is empty, Please pass ES_INDEX_SOURCE_FULL_PATH"
 exit 0
elif [[ "$RESTORE_ES_BINARIES" = true ]] && [[ -z "$ES_BINARIES_SOURCE_FULL_PATH" ]];then
 echo "ES_BINARIES_SOURCE_FULL_PATH is empty, Please pass ES_BINARIES_SOURCE_FULL_PATH"
 exit 0
elif [[ "$RESTORE_DB" = false ]] && [[ "$RESTORE_ES_INDEX" = false ]] && [[ "$RESTORE_ES_BINARIES" = false ]];then
 echo "Please pass any of parmeter value true and its path"
 usage
fi  

CUSTOMER_BUCKET_HASH=$(echo -n "${UPDATE_CUSTOMER}" | sha1sum | awk '{print $1}' | tr -d '\n')
CUSTOMER_BUCKET_NAME="nuxeo-data-backups-${CUSTOMER_BUCKET_HASH}"

if aws s3 ls "s3://${CUSTOMER_BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'
then
  echo "Destination backet : ${CUSTOMER_BUCKET_NAME}"
  CUSTOMER_BUCKET_NAME=nuxeo-data-backups-$(echo ${CUSTOMER_BUCKET_HASH} | cut -c1-10)
  echo "Destination backet truncate : ${CUSTOMER_BUCKET_NAME}"
  if aws s3 ls "s3://${CUSTOMER_BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'
  then
    echo "Destination bucket not exist"
    exit 1
  fi
fi

TSTAMP=$(date +"%Y%m%d-%H%M%S")

if $RESTORE_ES_INDEX; then
 cat index | jq  -r .snapshots[0]
 RESTORE_ES_INDEX=$(echo -n "${RESTORE_ES_INDEX}" | tr -d '*')
 aws s3 ls ${ES_INDEX_SOURCE_FULL_PATH}
 if [ $? -ne 0 ]; then
    echo "Source backup file path is not correct, DB backup file not exist"
    echo "Source bucket path : ${ES_INDEX_SOURCE_FULL_PATH}"
    exit 1
 fi
 rm -rf /tmp/index
 aws s3 cp ${ES_INDEX_SOURCE_FULL_PATH}index /tmp/index
 TSTAMP=$(cat /tmp/index | jq  -r .snapshots[0] | awk -F "-" '{print $3}')-$(cat /tmp/index | jq  -r .snapshots[0] | awk -F "-" '{print $4}')
 echo $TSTAMP
fi

echo "Using timestamp: $TSTAMP"

DATE=${TSTAMP:0:8}
YEAR=${TSTAMP:0:4}
MONTH=${TSTAMP:4:2}
DAY=${TSTAMP:6:2}

S3_BACKUP_LOCATION="$YEAR/$MONTH/$DAY/$TSTAMP"

echo "Uploading backup to customer bucket name ${CUSTOMER_BUCKET_NAME}"

if $RESTORE_DB ; then
   DB_SOURCE_FULL_PATH=$(echo -n "${DB_SOURCE_FULL_PATH}" | tr -d '*')
   aws s3 ls ${DB_SOURCE_FULL_PATH}
   if [ $? -ne 0 ]; then
      echo "Source backup file path is not correct, DB backup file not exist"
      echo "Source bucket path : ${DB_SOURCE_FULL_PATH}"
      exit 1
   fi
   echo "Copy Postgre dmp file from source s3 bucket to client bucket"
   latest_dmp=$(aws s3 ls ${DB_SOURCE_FULL_PATH} | grep ".dmp"  | sort  | tail -n 1  | awk '{print $4}')
   file_extention=${DB_SOURCE_FULL_PATH: -4}
   if [[ "${file_extention}" == ".dmp" ]]; then
    aws s3 cp  ${DB_SOURCE_FULL_PATH}  s3://${CUSTOMER_BUCKET_NAME}/restore_backups/${S3_BACKUP_LOCATION}/${latest_dmp}
   else
    aws s3 cp  ${DB_SOURCE_FULL_PATH}${latest_dmp}  s3://${CUSTOMER_BUCKET_NAME}/restore_backups/${S3_BACKUP_LOCATION}/${latest_dmp}
   fi
fi


if $RESTORE_ES_INDEX; then
   echo "Copy Elasticsearch backup from source s3 bucket to client bucket"
   aws s3 cp  ${ES_INDEX_SOURCE_FULL_PATH}  s3://${CUSTOMER_BUCKET_NAME}/restore_backups/${S3_BACKUP_LOCATION}/elasticsearch/ --recursive --exclude "*.dmp"
fi


if $RESTORE_ES_BINARIES; then
   ES_BINARIES_SOURCE_FULL_PATH=$(echo -n "${ES_BINARIES_SOURCE_FULL_PATH}" | tr -d '*')
   aws s3 ls ${ES_BINARIES_SOURCE_FULL_PATH}
   if [ $? -ne 0 ]; then
      echo "Source backup file path is not correct, DB backup file not exist"
      echo "Source bucket path : ${ES_BINARIES_SOURCE_FULL_PATH}"
      exit 1
   fi
   echo "Copy Elasticsearch backup from source s3 bucket to client bucket"
   aws s3 cp  ${ES_BINARIES_SOURCE_FULL_PATH}  s3://${CUSTOMER_BUCKET_NAME}/restore_backups/${S3_BACKUP_LOCATION}/binaries/ --recursive --exclude "*.dmp"
fi


VPC_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:aws:autoscaling:groupName,Values=${UPDATE_CUSTOMER}-${ENVIRONMENT}-nuxeo*" "Name=tag:service,Values=nuxeo" "Name=tag:project,Values=${CUSTOMER}"  --region ${AWS_REGION} --output text  --query "Reservations[0].Instances[0].VpcId" )

if [[ "${VPC_ID}" == "None" ]];then
      echo "Unable to get VPC" 
      exit 1
fi

echo "Bastion VPC ID : $VPC_ID"

BASTION_IP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=vpc-id,Values=${VPC_ID}"   "Name=tag:service,Values=bastion" "Name=tag:stack-identifier,Values=${UPDATE_CUSTOMER}" "Name=tag:project,Values=${CUSTOMER}"   --region $AWS_REGION | jq -r .Reservations[].Instances[].PublicIpAddress)

echo "Bastion Ip : $BASTION_IP"

ssh -ttq -i $ssh_key root@$BASTION_IP "bash /usr/local/nuxeo-backup/run_restore_script -e $ENVIRONMENT -c $UPDATE_CUSTOMER -d $TSTAMP -D $RESTORE_DB -E $RESTORE_ES_INDEX -B $RESTORE_ES_BINARIES -v $VPC_ID" 2> /dev/null
