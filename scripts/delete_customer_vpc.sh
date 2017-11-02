#!/bin/bash -e

set -ex

ABSOLUTE_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

BUCKET_NAME="nco-${AWS_ACCOUNT}-platform"

terraform version

[ -d ${CUSTOMER} ]

mkdir -p ${CUSTOMER}/VPC

echo "**************************************************"
echo "Configure Terraform Variables"
echo "**************************************************"

VPC_ID=$(aws ec2 describe-vpcs --region ${AWS_REGION} --filters Name=tag:Name,Values=${VPC_NAME} --output text  --query "Vpcs[0].VpcId")

response=$(aws ec2  describe-instances --region ${AWS_REGION} --filters "Name=vpc-id,Values=${VPC_ID}" --query "Reservations[].Instances[].InstanceId")

length=$(echo $response | jq '. | length')

if [ "$length" -gt 1 ];then
  echo "Other EC2 instance already exist in this VPC first delete that"
  exit 1
fi

VPC_CIDR=$(bash ${ABSOLUTE_PATH}/freeCIDR.sh $AWS_REGION $VPC_NAME)

VPC_STACK_NAME=$(echo ${VPC_NAME} | awk -F "_" '{print $2}')

cat <<EOF >> ${CUSTOMER}/VPC/terraform.tfvars

STACK_REGION = "${AWS_REGION}"

VPC_CIDR = {
   "${AWS_REGION}"="${VPC_CIDR}"
}

STACK_NAME = "${VPC_STACK_NAME}"

NCO_VERSION = "${NCO_RELEASE}"

EOF

MODULE_NAME="vpc"

cd ${CUSTOMER}/VPC

echo "**************************************************"
echo "Get Terraform Templates to Delete VPC"
echo "**************************************************"

cp -R ${MODULE_PATH}/nco-platform nco-platform

terraform init -no-color \
  -backend=true \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=tfstate/vpc/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/cloud_${VPC_STACK_NAME}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -from-module nco-platform/templates/${MODULE_NAME}


echo "**************************************************"
echo "Get Terraform Modules"
echo "**************************************************"


terraform get -no-color -update

## Fetch remote state if existent
terraform refresh -no-color

## Plan execution
terraform plan -no-color -out ${CUSTOMER}.plan

## Run Destroy
terraform destroy -force $(terraform state list | sed -e 's/^/-target=/' | sed 'N;s/\n/ /' )

## Delete State file from s3
aws s3 rm s3://${BUCKET_NAME}/tfstate/vpc/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/cloud_${VPC_STACK_NAME}/terraform.tfstate