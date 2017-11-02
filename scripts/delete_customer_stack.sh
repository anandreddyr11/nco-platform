#!/bin/bash -e

set -e


ABSOLUTE_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
BUCKET_NAME="nco-${AWS_ACCOUNT}-platform"
DATADOG_APIKEY="69e9df273af725d0304a8e8c23ee66f5"
DATADOG_APPKEY="f85f3cfc3653074f898efad07992339a82679abc"

delete_all_s3_bucket=$1

terraform version

[ -d ${CUSTOMER}/${ENVIRONMENT} ]

echo "**************************************************"
echo "Update ES resume-processes"
echo "**************************************************"

  set +e
  set -x

ES_BLUE_ASG_NAME="es-${UPDATE_CUSTOMER}-${ENVIRONMENT}-nuxeo-blue"
ES_GREEN_ASG_NAME="es-${UPDATE_CUSTOMER}-${ENVIRONMENT}-nuxeo-green"
aws autoscaling resume-processes --auto-scaling-group-name ${ES_BLUE_ASG_NAME} --region ${AWS_REGION}
aws autoscaling resume-processes --auto-scaling-group-name ${ES_GREEN_ASG_NAME} --region ${AWS_REGION}

  
echo "**************************************************"
echo "Deleting datadog dashboard"
echo "**************************************************"

    aws s3 ls s3://nuxeo-platform/datadog/${NCO_RELEASE}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/dashboard.json
    
    if [ $? -eq 0 ]; then
     aws s3 cp s3://nuxeo-platform/datadog/${NCO_RELEASE}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/dashboard.json /tmp/existing_${stack_name}_${date_time}.json
     dashboard_id=$(cat /tmp/existing_${stack_name}_${date_time}.json | jq -r .dashboard_id)
     echo "existing dashboard id : ${dashboard_id}"
     curl -X DELETE \
  "https://app.datadoghq.com/api/v1/screen/${dashboard_id}?api_key=${DATADOG_APIKEY}&application_key=${DATADOG_APPKEY}"
  aws s3 rm s3://nuxeo-platform/datadog/${NCO_RELEASE}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/dashboard.json
    fi 

    set +x
    set -e


echo "**************************************************"
echo "Configure Terraform Variables"
echo "**************************************************"

MODULE_NAME="stack"

sed -i  "/STACK_NAME /c\STACK_NAME = \"${UPDATE_CUSTOMER}\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

sed -i  "/STACK_URL /c\STACK_URL = \"${UPDATE_CUSTOMER}-${ENVIRONMENT}.nuxeocloud.com\" " ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars

cat <<EOF >> ${CUSTOMER}/${ENVIRONMENT}/terraform.tfvars
VPC_NAME = "${STACK_NAME}"
 
EOF


echo "**************************************************"
echo "Get Terraform Templates to build Customer"
echo "**************************************************"

cd ${CUSTOMER}/${ENVIRONMENT}

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


if $delete_all_s3_bucket ; then

terraform destroy -force $(terraform state list | sed -e 's/^/-target=/' | sed 'N;s/\n/ /') 

else

terraform destroy -force $(terraform state list | sed '/module.s3.aws_s3_bucket.bucket_backup/d' | sed '/module.s3.aws_iam_policy.replication/d' | sed '/module.s3.aws_iam_policy_attachment.replication/d' |  sed '/module.s3.aws_iam_role.replication/d' | sed '/module.s3.aws_s3_bucket.nuxeo_backup_replication/d'  | sed -e 's/^/-target=/' | sed 'N;s/\n/ /' ) 

fi

#Delete state file for backup
aws s3 rm s3://${BUCKET_NAME}/tfstate/customers/${NCO_RELEASE}/${CUSTOMER}/${AWS_REGION}/${ENVIRONMENT}/${UPDATE_CUSTOMER}/ --recursive