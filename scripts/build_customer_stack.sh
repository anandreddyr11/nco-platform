#!/bin/bash -e

set -ex

BUCKET_NAME="nco-${AWS_ACCOUNT}-platform"

terraform version

[ -d ${CUSTOMER}/${ENVIRONMENT} ]

echo "**************************************************"
echo "Configure Terraform Variables"
echo "**************************************************"

#AWS_REGION=$(cat ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars  |  grep REGION | awk -F'=' '{print $2}' | tr -d '" ')

MODULE_NAME="stack"

sed -i  "/STACK_NAME /c\STACK_NAME = \"${UPDATE_CUSTOMER}\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

sed -i  "/STACK_URL /c\STACK_URL = \"${UPDATE_CUSTOMER}-${ENVIRONMENT}.nuxeocloud.com\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

VPC_ID=$(echo "${VPC_NAME}" | awk -F "|" '{print $2}')

infrastructure_version=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION} --query "Vpcs[].{version: Tags[?Key=='infrastructure-version'] | [0].Value}" --output text)

if [ "$infrastructure_version" == "None" ]
   then
      echo "infrastructure-version tag not set on VPC - ${VPC_ID}" 
      exit 1
fi

VPC_NAME=$(echo "${VPC_NAME}" | awk -F "|" '{print $1}')

cat <<EOF >> ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars
VPC_NAME = "${VPC_NAME}"
AWS_ACCOUNT = "${AWS_ACCOUNT}"
VPC_RELEASE_VERSION =  "${infrastructure_version}"
EOF

cd ${CUSTOMER}/${ENVIRONMENT}

STACK_ENVIRONMENT=$(cat terraform.tfvars | grep STACK_ENVIRONMENT | awk -F "=" '{print $2}' | sed 's/\"//g' |  sed 's/ //g'  | tr -d "\n")

if [[ ! "${STACK_ENVIRONMENT}" ]];then
  echo "STACK_ENVIRONMENT variables not found in TF file"
  exit 1
fi

aws s3 cp terraform.tfvars s3://${BUCKET_NAME}/tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${STACK_ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfvars

echo "**************************************************"
echo "Get Terraform Templates to build Customer"
echo "**************************************************"

cp -R ${MODULE_PATH}/nco-platform nco-platform

cp ${MODULE_PATH}/nco-platform/templates/account/${AWS_ACCOUNT}-inputs.tf nco-platform/templates/${MODULE_NAME}/inputs.tf

terraform init -no-color \
  -backend=true \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${STACK_ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -from-module nco-platform/templates/${MODULE_NAME}

echo "**************************************************"
echo "Get Terraform Modules"
echo "**************************************************"

terraform get -no-color -update

## Fetch remote state if existent
terraform refresh -no-color

## Plan execution
terraform plan -no-color -out ${CUSTOMER}-${STACK_ENVIRONMENT}.plan

## Provision
terraform apply -no-color

#Copy state file for backup
aws s3 cp s3://${BUCKET_NAME}/tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${STACK_ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate s3://${BUCKET_NAME}/tfstate_backup/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${STACK_ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate