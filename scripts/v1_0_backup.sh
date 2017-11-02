#!/bin/bash -e
set -e


################################################################################
# File:    v1_0_backup.sh
# Purpose: Use this script to take a full or partial backup from v1.0 stacks
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-07-30
# Help: bash v1_0_backup.sh -h
################################################################################


####################################################
###############  Global Variable ###################
####################################################

S3_BUCKET_NAME="nuxeo-ccir-migration-test"
DBHOST="localhost"
DBPORT=5433
DBNAME=nuxeo
DBNAME=nuxeo

BACKUP_ES_INDEX=false
BACKUP_ES_BINARIES=false
BACKUP_DB=false

TSTAMP=$(date +"%Y%m%d-%H%M%S")
DATE=${TSTAMP:0:8}
YEAR=${TSTAMP:0:4}
MONTH=${TSTAMP:4:2}
DAY=${TSTAMP:6:2}


usage()
{
    echo -e "Use this script to take a full or partial backup from v1.0 stacks"
    echo -e "-d  Backup Database, default false"
    echo -e "-e  Backup Elasticsearch index, default false"
    echo -e "-b  Backup Elasticsearch binaries, default false"
    echo -e "-h  help "
    exit 1
}


####################################################
###############  PARSE ARGUMENTS ###################
####################################################


while getopts "d:e:b:" opt; do

  case $opt in
    d)
      BACKUP_DB=$OPTARG
      ;;        
    e)
      BACKUP_ES_INDEX=$OPTARG
      ;;
    b)
      BACKUP_ES_BINARIES=$OPTARG
      ;;
    \?)
      usage
      ;;
  esac

done


if [ "$BACKUP_DB" = false ] && [ "$BACKUP_ES_INDEX" = false ] && [ "$BACKUP_ES_BINARIES" = false ]; then
    echo "All the parameter is false, Please pass any of parameter true"
    usage 
fi

# ElasticSearch Index backup
if $BACKUP_ES_INDEX; then

	echo "*** Backing up Elasticsearch..."
	mkdir -p /migr/backups/elasticsearch
	chmod 0777 /migr/backups/elasticsearch
	rm -rf /migr/backups/elasticsearch/*
	curl -XPUT http://localhost:9200/_snapshot/backup -d "{\"type\":\"fs\", \"settings\": {\"location\": \"/migr/backups/elasticsearch/$DATE\"}}"
	curl -XPUT http://localhost:9200/_snapshot/backup/nuxeo-es-$TSTAMP?wait_for_completion=true -d '{"ignore_unavailable": "true"}'
	curl -XDELETE http://localhost:9200/_snapshot/backup
	echo "*** Elasticsearch backup finish"

	# Upload other backups to S3
	echo "*** Uploading Elasticsearch backups to S3..."
	aws s3 cp /migr/backups/elasticsearch/$DATE s3://${S3_BUCKET_NAME}/backups/$YEAR/$MONTH/$DAY/$TSTAMP/elasticsearch/ --recursive
	echo "finish"

fi

# Postgres backup
if $BACKUP_DB; then

	echo "*** Backing up PostgreSQL..."
	if [ -d /migr/backups/postgresql ]; then
	    rm -rf /migr/backups/postgresql
	fi
	mkdir -p /migr/backups/postgresql
	pg_dump -Fc -f /migr/backups/postgresql/db-$TSTAMP.dmp -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME

	# Upload other backups to S3
	echo "*** Uploading backups to S3..."
	aws s3 cp /migr/backups/postgresql/ s3://${S3_BUCKET_NAME}/backups/$YEAR/$MONTH/$DAY/$TSTAMP/ --recursive
    echo "finish"
fi



# Elasticsearch binaries backup
if $BACKUP_ES_BINARIES; then

	echo "*** Backing up Elasticsearch binaries..."
	sudo find /data/nuxeo/binaries/data -iname '*' -exec cp \{\} /migr/migration \;

	echo "*** Uploading backups to S3..."
	aws s3 cp /migr/binaries/ s3://${S3_BUCKET_NAME}/backups/$YEAR/$MONTH/$DAY/$TSTAMP/binaries/ --recursive
    echo "finish"
    
fi

echo "*** all backup upload this location"
echo s3://${S3_BUCKET_NAME}/backups/$YEAR/$MONTH/$DAY/$TSTAMP/
