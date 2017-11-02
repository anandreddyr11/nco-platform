#!/bin/bash -e

set -e

ABSOLUTE_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

BUCKET_NAME="nco-${AWS_ACCOUNT}-platform"

terraform version

[ -d ${CUSTOMER}/${ENVIRONMENT} ]

echo "**************************************************"
echo "Configure Terraform Variables"
echo "**************************************************"

MODULE_NAME="stack"

sed -i  "/STACK_NAME /c\STACK_NAME = \"${UPDATE_CUSTOMER}\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

sed -i  "/STACK_URL /c\STACK_URL = \"${UPDATE_CUSTOMER}-${ENVIRONMENT}.nuxeocloud.com\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

VPC_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:aws:autoscaling:groupName,Values=*${UPDATE_CUSTOMER}-${ENVIRONMENT}-nuxeo*" "Name=tag:project,Values=${CUSTOMER}" --region ${AWS_REGION} --output text --query "Reservations[0].Instances[0].VpcId")

infrastructure_version=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION} --query "Vpcs[].{version: Tags[?Key=='infrastructure-version'] | [0].Value}" --output text)

if [ "$infrastructure_version" == "None" ]
   then
      echo "infrastructure-version tag not set on VPC - ${VPC_ID}" 
      exit 1
fi

VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION}  --output text --query "Vpcs[].{name: Tags[?Key=='Name'] |  [0].Value}")

cat <<EOF >> ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars
VPC_NAME = "${VPC_NAME}"
AWS_ACCOUNT = "${AWS_ACCOUNT}"
VPC_RELEASE_VERSION =  "${infrastructure_version}"
EOF

cd ${CUSTOMER}/${ENVIRONMENT}

aws s3 cp terraform.tfvars s3://${BUCKET_NAME}/tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfvars

echo "**************************************************"
echo "Get Terraform Templates to build Customer"
echo "**************************************************"

cp -R ${MODULE_PATH}/nco-platform nco-platform

cp ${MODULE_PATH}/nco-platform/templates/account/${AWS_ACCOUNT}-inputs.tf nco-platform/templates/${MODULE_NAME}/inputs.tf

terraform init -no-color \
  -backend=true \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -from-module nco-platform/templates/${MODULE_NAME}

echo "**************************************************"
echo "Get Terraform Modules"
echo "**************************************************"

terraform get -no-color -update

## Fetch remote state if existent
terraform refresh -no-color

## Plan execution
terraform plan -no-color -out ${CUSTOMER}-${ENVIRONMENT}.plan

## Provision
terraform apply -no-color

#Copy state file for backup
aws s3 cp s3://${BUCKET_NAME}/tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate s3://${BUCKET_NAME}/tfstate_backup/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/terraform.tfstate
