#!/bin/bash

set -ex

################################################################################
# File:    nuxeo_jenkins_restore.sh
# Purpose: This script use for restore jenkins backup
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-10-04
# Usage:   bash nuxeo_jenkins_restore.sh <account>
################################################################################


AWS_ACCOUNT=$1
JENKINS_HOME_DIR="/jenkins_data"

if [[ -z "${AWS_ACCOUNT}" ]];then
 echo "Please pass account name nxio/hosting"
 exit 1
fi	

BACKUP_BUCKET_NAME="nco-${AWS_ACCOUNT}-jenkins-backups"
cd ${JENKINS_HOME_DIR}

aws s3 cp s3://${BACKUP_BUCKET_NAME}/latest-backup.json ${JENKINS_HOME_DIR}/latest-backup.json

latest_backup=$(cat  ${JENKINS_HOME_DIR}/latest-backup.json  | jq -r .latest_backup)

echo "latest backup file name : ${latest_backup}"

echo "stop jenkins"

service jenkins stop

sleep 10

echo "delete existing jenkins directory"

rm -rf jenkins

echo "downloading latest backup from s3 bucket"

aws s3 cp s3://${BACKUP_BUCKET_NAME}/${latest_backup} /jenkins_data/

echo "extracting backup to jenkins home directory"

tar -xzf ${latest_backup}

# Need to do manuall restart

#echo "start jenkins"

#service jenkins start

#sleep 10

rm -rf ${latest_backup}

rm -rf ./latest-backup.json