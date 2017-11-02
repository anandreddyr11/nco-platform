#!/bin/bash

set -ex

################################################################################
# File:    build_ansible_var_file.sh
# Purpose: Read nuxeo customer package from its TF variable file
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-06-28
# RUN: bash build_ansible_var_file.sh demo dev
################################################################################

customer_name=$1
environment=$2
customers_workspace=$3

if [[ -z $customer_name ]] || [[ -z $environment ]];then
echo "Please pass customer name and environment name"
exit 1
fi	

if [[ "$customer_name" == "generic" ]];then
echo "Use ansible default nuxeo packages"	
exit 0
fi	


rm -rf /opt/${customer_name}-${environment}.yml

write_to_yml()
{
key=$1
value=$2
if [[ ! -z "${value}" ]];then
cat <<EOF >> /opt/${customer_name}-${environment}.yml
${key}: ${value}
EOF
fi
}

NUXEO_PACKAGES=$(cat ${customers_workspace}/${customer_name}/${environment}/terraform.tfvars | grep NUXEO_PACKAGES | awk -F "=" '{print $2}' | sed 's/\"//g')
write_to_yml NUXEO_PACKAGES "${NUXEO_PACKAGES}"

NUXEO_RELAX_NONE_PACKAGES=$(cat ${customers_workspace}/${customer_name}/${environment}/terraform.tfvars | grep NUXEO_RELAX_NONE_PACKAGES | awk -F "=" '{print $2}' | sed 's/\"//g')
write_to_yml NUXEO_RELAX_NONE_PACKAGES "${NUXEO_RELAX_NONE_PACKAGES}"

NUXEO_DATADOG_APIKEY=$(cat ${customers_workspace}/${customer_name}/${environment}/terraform.tfvars | grep DATADOG_APIKEY | awk -F "=" '{print $2}' | sed 's/\"//g')
write_to_yml DATADOG_APIKEY "${NUXEO_DATADOG_APIKEY}"

INSTANCE_CLID_PART1=$(cat ${customers_workspace}/${customer_name}/${environment}/terraform.tfvars | sed -n '/INSTANCE_CLID/,/EOF/p' |  sed "2q;d")
INSTANCE_CLID_PART2=$(cat ${customers_workspace}/${customer_name}/${environment}/terraform.tfvars | sed -n '/INSTANCE_CLID/,/EOF/p' |  sed "3q;d")

if [[ ! -z $INSTANCE_CLID_PART1 ]];then
cat <<EOF >> /opt/${customer_name}-${environment}.yml
INSTANCE_CLID: |
  ${INSTANCE_CLID_PART1}
  ${INSTANCE_CLID_PART2}
EOF
fi