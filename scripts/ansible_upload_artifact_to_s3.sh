#!/bin/bash

set -ex

# USAGE: 
# This script use for push ansible artifact from git repo to customer s3

current_date=`date +%s`
customers=()

# Create tar file from git workspace
create_tar()
{
  cd ${ARTIFACT_DIRECTORY}/ansible
  tar -czf ansible.nuxeo.${current_date}.tar.gz *
}

# Copy artifact from git to s3 bucket of each customer
copy_artifact()
{
   
  echo "customer : ${CUSTOMER}"
  echo "environment : ${ENVIRONMENT}"
  bucket_sha_sum=$(echo -n "${CUSTOMER}" | sha1sum | awk '{print $1}' | cut -c1-10 |  tr -d '\n')
  bucket_name="nco-${AWS_ACCOUNT}-configs-${bucket_sha_sum}"
  echo "bucket_name : ${bucket_name}"
  cd ${ARTIFACT_DIRECTORY}/ansible
  echo "VERSION=${current_date}" > ${ENVIRONMENT}.latest
  aws s3 cp ansible.nuxeo.${current_date}.tar.gz s3://${bucket_name}/ansible/
  aws s3 cp ${ENVIRONMENT}.latest s3://${bucket_name}/ansible/${ENVIRONMENT}.latest
}

# Check duplicate customer
function check_duplicate_customer() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

if [[ -z "${CUSTOMER}" ]] && [[ -z "${ENVIRONMENT}" ]];then
 echo -e "Please pass environment"
 exit 1
fi  

create_tar

copy_artifact 

echo "Upload ansible artifact for following customers"
echo "${customers[@]}"
echo "Latest VERSION=${current_date}"
echo "Latest ansible artifact=ansible.nuxeo.${current_date}.tar.gz"
