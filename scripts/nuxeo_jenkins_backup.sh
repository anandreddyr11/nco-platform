#!/bin/bash

set -ex

################################################################################
# File:    nuxeo_jenkins_backup.sh
# Purpose: This script use for take jenkins backup
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-10-04
# Usage:   bash nuxeo_jenkins_backup.sh <account>
################################################################################

AWS_ACCOUNT=$1
EXCLUDE_DIR=$2
JENKINS_HOME_DIR="/jenkins_data"


if [[ -z "${AWS_ACCOUNT}" ]];then
 echo "Please account namme nxio/hosting"
 exit 1
fi  


BACKUP_BUCKET_NAME="nco-${AWS_ACCOUNT}-jenkins-backups"
cd ${JENKINS_HOME_DIR}

if [ ! -d "jenkins" ]; then
  exit 0
fi

backupFileName="jenkins-backup-$(date +"%Y-%m-%d-%I-%M-%p").tar.gz"

echo "Backup file name : ${backupFileName}"

set +e
count=1
while [ $count -le 5 ]
do
    echo "Creating tar with try ${count}"
    
    if [[ -z "${EXCLUDE_DIR}" ]];then
     tar -cPzf  ${backupFileName} ./jenkins
    else
     tar --exclude=${EXCLUDE_DIR} -cPzf  ${backupFileName} ./jenkins
    fi 
    
    if [ $(echo $?) -ne 0 ]; then 
      sleep 30
      rm -rf jenkins-backup-*
    else 
      break;
    fi
    count=$(( $count + 1 ))
     
     if [ $count -ge 5 ];then
     	echo "Tar creation failed after 5 try"
     	exit 1
     fi	

done 
set -e

rm -rf /tmp/latest-backup.json

aws s3 cp ${backupFileName}  s3://${BACKUP_BUCKET_NAME}/${backupFileName}

echo "Backup uploaded successfully"

cat <<EOF > /tmp/latest-backup.json
{
"latest_backup" : "${backupFileName}"
}
EOF

aws s3 cp /tmp/latest-backup.json  s3://${BACKUP_BUCKET_NAME}/latest-backup.json

echo "Updated latest-backup.json- latest-backup : ${backupFileName}"

rm -rf ${backupFileName}