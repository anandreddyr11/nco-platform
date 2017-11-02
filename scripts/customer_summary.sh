#!/bin/bash 
set -e

################################################################################
# File:    customer_summary.sh
# Purpose: Show Nuxeo Customer Summary 
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-06-13
################################################################################


usage()
{
    echo -e "This script use for show customer summary"
    echo -e "-c  Customer name"
    echo -e "-e  Customer environment"
    echo -e "-s  Statck name"
    echo -e "-h  help  ${NORM}"
    exit 1
}

####################################################
###############  PARSE ARGUMENTS ###################
####################################################

while getopts "h:c:e:s:r:" opt; do

  case $opt in
    h)
      usage
      ;;
    c)
      CUSTOMER="$OPTARG"
      ;;        
    e)
      CUSTOMER_ENVIRONMENT="$OPTARG"
      ;;
    s)
      STACK_NAME="$OPTARG"
      ;;
    r)
      REGION="$OPTARG"
      ;;      
    \?)
      usage
      ;;
  esac

done

if [[ -z ${CUSTOMER} ]] || [[ -z ${CUSTOMER_ENVIRONMENT} ]] || [[ -z ${STACK_NAME} ]];then
  echo -e "Please pass required arguments"
  usage
fi

CLOUD_NAME="cloud_${STACK_NAME}"

vpc_id=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:aws:autoscaling:groupName,Values=*${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo*" "Name=tag:project,Values=${CUSTOMER}" --region ${REGION} --output text --query "Reservations[0].Instances[0].VpcId")

file_name="detail_"`date +%s`

echo -e "Component\tType\tSize\tName\tDetails" >> /tmp/${file_name}
 
write_details()
{
  component=$1
  type=$2
  size=$3
  name=$4
  details=$5
  echo -e "${component}\t${type}\t${size}\t${name}\t${details}" >> /tmp/${file_name}
}



describe_instances_ec2()
{
  COUNTER=0
  component=$1
  input_fileter=$2
  response=$(aws ec2 describe-instances --filter $input_fileter --region ${REGION} --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value, instance_id: InstanceId, ip_address: PrivateIpAddress, state: State.Name, instance_type: InstanceType }" --output json)
  length=$(echo $response | jq '. | length')

  while [  $COUNTER -lt $length ]; do
     name=$(echo $response | jq -r .[0][].name)
     instance_type=$(echo $response | jq -r .[0][].instance_type)
     private_ip=$(echo $response | jq -r .[0][].ip_address)
     write_details "${component}" "EC2" "${instance_type}" "${name}"  "PrivateIp : ${private_ip}"
     let COUNTER=COUNTER+1 
  done

}

describe_rds()
{
  instance_identifier=$1
  response=$(aws rds describe-db-instances --db-instance-identifier ${instance_identifier} --region ${REGION} --query "DBInstances[0].{ db_instance_class:DBInstanceClass, db_instance_identifier:DBInstanceIdentifier,version:EngineVersion}" --output json)
  size=$(echo $response | jq -r .db_instance_class)
  identifier=$(echo $response | jq -r .db_instance_identifier)
  version=$(echo $response | jq -r .version)
  write_details "Nuxeo DB Server" "RDS" "${size}" "${identifier}"  "Version : ${version}"
}

describe_elasticache()
{
  cache_cluster_id=$1
  cache_cluster_id=$(echo $cache_cluster_id | cut -c1-20)
  response=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cache_cluster_id} --region ${REGION} --query "CacheClusters[0].{ cache_node_type:CacheNodeType,engine_version:EngineVersion,cahe_type:Engine}" --output json)
  size=$(echo $response | jq -r .cache_node_type)
  version=$(echo $response | jq -r .engine_version)
  write_details "Nuxeo Redis Server" "ELASTICACHE" "${size}" "${cache_cluster_id}"  "Version : ${version}"
}


describe_vpc()
{
  response=$(aws ec2 describe-vpcs --vpc-ids ${vpc_id} --region ${REGION}  --query Vpcs[0].{cidr_block:CidrBlock})
  cidr_block=$(echo $response | jq -r .cidr_block)
  write_details "Nuxeo VPC" "VPC" "-" "${CLOUD_NAME}"  "CidrBlock : ${cidr_block}"
}


describe_alb()
{
  alb_name=$1
  response=$(aws elbv2 describe-load-balancers --names ${alb_name} --region ${REGION} --query LoadBalancers[0].{dns_record:DNSName})
  dns_record=$(echo $response | jq -r .dns_record)
  write_details "Nuxeo ALB" "ALB" "-" "${alb_name}"  "DNS : ${dns_record}" 
}


describe_asg()
{
  COUNTER=0
  component=$1
  asg_name=$2
  response=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${asg_name} --region ${REGION} --query "AutoScalingGroups[].{min_size: MinSize,max_size: MaxSize, desired_capacity:DesiredCapacity, launch_config:LaunchConfigurationName}")
  length=$(echo $response | jq '. | length')
  if [[ $length -eq 1 ]];then
    min_size=$(echo $response | jq -r .[].min_size)
    max_size=$(echo $response | jq -r .[].max_size)
    desired_size=$(echo $response | jq -r .[].desired_capacity)
    launch_config=$(echo $response | jq -r .[].launch_config)
    capicity="(${min_size}/${max_size}/${desired_size})"

    write_details "${component} ASG" "ASG" "-" "${asg_name}"  "min/max/desired : ${capicity}" 
    write_details "${component} LaunchConfig" "LaunchConfig" "-" "${launch_config}"  "-" 
  fi  
}




#Get nuxeo EC2 Server Details
describe_instances_ec2 "Nuxeo App Server" "Name=tag:aws:autoscaling:groupName,Values=${STACK_NAME}-${CUSTOMER_ENVIRONMENT}*" 
describe_instances_ec2 "Nuxeo Dedicated ES" "Name=tag:aws:autoscaling:groupName,Values=es-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}*" 
describe_instances_ec2 "Nuxeo Dedicated Worker" "Name=tag:aws:autoscaling:groupName,Values=worker-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}*" 
describe_instances_ec2 "Nuxeo Bastion" "Name=tag:Name,Values=bastion-* Name=vpc-id,Values=${vpc_id}" 

# Get RDS details
describe_rds "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo"

# Get Elasticache details
describe_elasticache "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}"

# Get VPC Details
describe_vpc

# Get ALB Details
describe_alb "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}"

# Get ASG Details 
# For Nuxeo App
describe_asg "Nuxeo App Blue" "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-1-blue"
describe_asg "Nuxeo App Green" "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-1-green"
describe_asg "Nuxeo App Blue" "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-0-blue"
describe_asg "Nuxeo App Green" "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-0-green"

# For ES 
describe_asg "Nuxeo ES Blue" "es-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-blue"
describe_asg "Nuxeo ES Green" "es-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-green"

# For Worker
describe_asg "Nuxeo Worker Blue" "worker-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-blue"
describe_asg "Nuxeo Worker Green" "worker-${STACK_NAME}-${CUSTOMER_ENVIRONMENT}-nuxeo-green"


# Route 53 record
write_details "Nuxeo App Endpoint" "ROUTE53" "-" "${CUSTOMER}-${CUSTOMER_ENVIRONMENT}.hosting.nuxeo.com"  "-" 

# S3 bucket
sha1_sum=$(echo -n "${STACK_NAME}" | sha1sum | awk '{print $1}' | tr -d '\n')

write_details "Nuxeo App Binary S3" "S3" "-" "nuxeo-${CUSTOMER_ENVIRONMENT}-${sha1_sum}"  "-" 
write_details "Nuxeo Backup S3" "S3" "-" "nuxeo-backup-${sha1_sum}"  "-" 
write_details "Nuxeo App Replication S3" "S3" "-" "nuxeo-${CUSTOMER_ENVIRONMENT}-rep-${sha1_sum}"  "-" 
write_details "Nuxeo Backup Replication S3" "S3" "-" "nuxeo-backup-rep-${sha1_sum}"  "-" 
write_details "Nuxeo File systems" "FS" "-" "${STACK_NAME}-${CUSTOMER_ENVIRONMENT}"  "-" 










echo -e "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
sed -e 's/\t/@| /g' /tmp/${file_name} | column -t -s '@'  | awk '1;!(NR%1){print "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------";}'

rm -rf /tmp/${file_name} 