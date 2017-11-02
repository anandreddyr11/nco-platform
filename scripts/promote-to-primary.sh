#!/bin/bash 
set -ex

################################################################################
# File:    promote-to-primary.sh
# Purpose: Prepare secondary Jenkins for use
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-10-09
# To Run:  promote-to-primary.sh <account-name> 
#            <account-name> should be nxio or hosting
################################################################################


AWS_ACCOUNT=$1
SERVICE="jenkins"
HOSTED_ZONE_ID="Z2YNPTI9GIHEBN"

# These are the parameters for NXIO account

AWS_REGION="us-east-2"
ELB="jenkins-nxio-use2"
DOMAIN_NAME="deploy-nxio.nuxeocloud.com."
SECONDARY_JENKINS="deploy-nxio-use2.nuxeocloud.com."


if [[ -z "${AWS_ACCOUNT}" ]];then
 echo "Enter valid account name: nxio/hosting"
 exit 1
fi 


if [[ $AWS_ACCOUNT == "hosting" ]];then
  # Updating parameters for HOSTING account

  AWS_REGION="us-west-2"
  ELB="jenkins-hosting-usw2"
  DOMAIN_NAME="deploy-hosting.nuxeocloud.com."
  SECONDARY_JENKINS="deploy-hosting-usw2.nuxeocloud.com."
fi



service jenkins start
echo "Jenkins service started successfully." 

echo "Updating Health-Check for ELB: ${ELB}"

UPDATED_ELB=$(aws elb configure-health-check --load-balancer-name ${ELB}  --region ${AWS_REGION} --health-check Target=HTTP:8080/login?from=%2F,Interval=10,UnhealthyThreshold=2,HealthyThreshold=10,Timeout=5)

echo "ELB Health-Check Updated"
echo $UPDATED_ELB  | jq '.'

echo "Updating Route 53 for Hosted Zone: ${HOSTED_ZONE_ID}"


if [[ $AWS_ACCOUNT == "nxio" ]];then
  export AWS_ACCESS_KEY_ID=AKIAIBH7LBL4HFR63S6A
  export AWS_SECRET_ACCESS_KEY=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
fi

cat <<EOF > /tmp/change-resource-record-sets.json
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${SECONDARY_JENKINS}"
          }
         
        ]
      }
    }
  ]
}
EOF

ROUTE_53="/tmp/change-resource-record-sets.json"
updated_route53=$(aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://${ROUTE_53})
echo $updated_route53

rm -rf ${ROUTE_53}

echo "Route53 record updated: Now its pointing to SECONDARY JENKINS"


echo "Updating Crontab: STOP-RESTORE and START-BACKUP"
cat <<EOF > /tmp/updated
# Uncomment the below script to start restore cron job.
#30 */1 * * * sudo /bin/bash  /usr/local/nuxeo/nuxeo_jenkins_restore.sh  nxio  >> /var/log/nuxeo-jenkins-restore.log 2>&1


# comment the below script to stop backup cron job.
15 */1 * * * sudo /bin/bash /usr/local/nuxeo/nuxeo_jenkins_backup.sh nxio >> /var/log/nuxeo-jenkins-backup.log 2>&1
EOF

crontab -u root /tmp/updated
rm -rf /tmp/updated