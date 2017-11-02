#!/bin/bash

set -e

################################################################################
# File:    nuxeo_datadog_dashboard.sh
# Purpose: This script use for create datadog dashboard
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-09-8
################################################################################

DATADOG_APIKEY="69e9df273af725d0304a8e8c23ee66f5"
DATADOG_APPKEY="f85f3cfc3653074f898efad07992339a82679abc"
BUCKET_NAME="nuxeo-platform"

height=15
width=50
past_hour=4h
past_hour=4h
past_minutes=5m
date_time=`date -u +%m-%d-%y-%H-%M-%S`

# Check version
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Increment y axis value
function increment()
{
   local sum=$(expr "$1" + "$2")
   echo $sum
}

# Create App dashboard metrics json
get_app_dashboard_body()
{
    
	node_names=$1
	stack_name=$2
	app_y_axis=$3
  app_dashboard=""
	nodes=$(echo $node_names | tr "," "\n")

	for node_name in $nodes
	do

	app_y_axis=$(increment $app_y_axis 20)

app_request_body=$(cat <<-END
{ 
          "type": "timeseries",
          "title": true,
          "title_size": 16,
          "title_align": "left",
          "title_text": "Core Session Count ($node_name)",
          "title": "Core Session Count ($node_name)",
          "height": $height,
          "width": $width,
          "timeframe": "${past_hour}",
          "y": app_y_axis=$(increment $app_y_axis 0),
          "x": 2,
          "tile_def":{
            "viz":"timeseries",
            "requests":[
                 {
                  "q": "avg:nuxeo.repositories.sessions{host:$node_name}",
                  "aggregator": "avg",
                  "conditional_formats": [],
                  "type": "line"
                }
            ],
            "autoscale":true
        }
      },
      { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Nuxeo Connections Pool ($node_name)",
              "title": "Nuxeo Connections Pool ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 0),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                    {
                      "q": "avg:nuxeo.repositories.repository_default.connections.idle{host:$node_name}",
                      "aggregator": "avg",
                      "conditional_formats": [],
                      "type": "line"
                    },
                    {
                      "q": "avg:nuxeo.repositories.jdbc_nuxeo.connections.idle{host:$node_name}",
                      "type": "line"
                    },
                    {
                      "q": "avg:nuxeo.repositories.jdbc_nuxeo.connections.count{host:$node_name}",
                      "type": "line"
                    },
                    {
                      "q": "avg:nuxeo.repositories.repository_default.connections.count{host:$node_name}",
                      "type": "line"
                    },
                    {
                      "q": "avg:nuxeo.repositories.jdbc_nxactivities.connections.idle{host:$node_name}",
                      "type": "line"
                    },
                    {
                      "q": "avg:nuxeo.repositories.jdbc_nxactivities.connections.count{host:$node_name}",
                      "type": "line"
                    }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Open CoreSession ($node_name)",
              "title": "Open CoreSession ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 20),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:nuxeo.repositories.default.sessions{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Nuxeo Logged Users ($node_name)",
              "title": "Nuxeo Logged Users ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 20),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:nuxeo.web.authentication.logged_users{host:$node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Number of PictureViews being processed ($node_name)",
              "title": "Number of PictureViews being processed ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 20),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:nuxeo.works.pictureViewsGeneration.running{$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Picture View Average Processing Time (s) ($node_name)",
              "title": "Picture View Average Processing Time (s) ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1mo",
              "y": app_y_axis=$(increment $app_y_axis 20),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:nuxeo.works.pictureViewsGeneration.total.mean{host:$node_name} / 1000",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Number of picture views to generate (Scheduled-Processed) ($node_name)",
              "title": "Number of picture views to generate (Scheduled-Processed) ($node_name)",
              "height": $height,
              "width": 102,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 20),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:nuxeo.works.pictureViewsGeneration.scheduled.count{host:$node_name} - avg:nuxeo.works.pictureViewsGeneration.completed{host:$node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "CPU ($node_name)",
              "title": "CPU ($node_name)",
              "height": $height,
              "width": 70,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 40),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:system.cpu.user{host:$node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.system{host:$node_name}",
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.idle{host:$node_name}",
                          "type": "line"
                      }                      
                ],
                "autoscale":true
            }
          },
          { 
              "type": "change",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "nuxeo.repositories.default.documents.create ($node_name)",
              "title": "nuxeo.repositories.default.documents.create ($node_name)",
              "height": $height,
              "width": 30,
              "timeframe": "1h",
              "y": app_y_axis=$(increment $app_y_axis 40),
              "x": 74,
              "tile_def":{
                "viz":"change",
                "requests":[
                      {
                        "extra_col": "",
                        "change_type": "absolute",
                        "order_dir": "desc",
                        "compare_to": "hour_before",
                        "q": "avg:nuxeo.repositories.default.documents.create{$node_name}",
                        "increase_good": false,
                        "order_by": "change"
                      }
                ],
                "autoscale":true
            }
          },
           { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Nuxeo Transactions ($node_name)",
              "title": "Nuxeo Transactions ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1mo",
              "y": app_y_axis=$(increment $app_y_axis 60),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                        {
                        "q": "avg:nuxeo.transactions.duration.p99{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:nuxeo.transactions.duration.mean{host:$node_name}",
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Nuxeo Transaction Rollbacks ($node_name)",
              "title": "Nuxeo Transaction Rollbacks ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 60),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                         {
                            "q": "avg:nuxeo.transactions.rollbacks{host:$node_name}",
                            "aggregator": "avg",
                            "conditional_formats": [],
                            "type": "line"
                          },
                          {
                            "q": "avg:nuxeo.transactions.concurrents.count{host:$node_name}",
                            "type": "line"
                          },
                          {
                            "q": "avg:nuxeo.transactions.concurrents.count{host:$node_name}",
                            "type": "line"
                          }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Nuxeo Auth Requests ($node_name)",
              "title": "Nuxeo Auth Requests ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 80),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:nuxeo.web.authentication.requests.count.p95{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:nuxeo.web.authentication.requests.count.mean{host:$node_name}",
                        "type": "line"
                      },
                      {
                        "q": "avg:nuxeo.web.authentication.requests.count.1MinuteRate{host:$node_name}",
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Killed sessions ($node_name)",
              "title": "Killed sessions ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1mo",
              "y": app_y_axis=$(increment $app_y_axis 80),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:nuxeo.repositories.jdbc_nuxeo.connections.killed{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:nuxeo.repositories.repository_default.connections.killed{host:$node_name}",
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "LDAP Cache Size ($node_name)",
              "title": "LDAP Cache Size ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1mo",
              "y": app_y_axis=$(increment $app_y_axis 100),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:nuxeo.directories.userDirectory.cache.size{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "PostgreSQL Commits / Rollbacks / Deadlocks ($node_name)",
              "title": "PostgreSQL Commits / Rollbacks / Deadlocks ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1mo",
              "y": app_y_axis=$(increment $app_y_axis 100),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                           {
                              "q": "avg:postgresql.commits{host:$node_name}",
                              "aggregator": "avg",
                              "conditional_formats": [],
                              "type": "line"
                            },
                            {
                              "q": "avg:postgresql.rollbacks{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:postgresql.deadlocks{host:$node_name}",
                              "type": "line"
                            }
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Disk ($node_name)",
              "title": "Disk ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 120),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:system.disk.used{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:system.disk.free{host:$node_name}",
                        "type": "line"
                      },                      
                      {
                        "q": "avg:system.disk.total{host:$node_name}",
                        "type": "line"
                      },  
                      {
                        "q": "avg:system.disk.in_use{host:$node_name}",
                        "type": "line"
                      }                                                   
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Memory ($node_name)",
              "title": "Memory ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": app_y_axis=$(increment $app_y_axis 120),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                           {
                              "q": "avg:system.mem.used{host:$node_name}",
                              "aggregator": "avg",
                              "conditional_formats": [],
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.free{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.total{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.usable{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.cached{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.slab{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.shared{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.buffered{host:$node_name}",
                              "type": "line"
                            }
                ],
                "autoscale":true
            }
          }
END
)
  app_y_axis=$(increment $app_y_axis 120)
	if [[ -z ${app_dashboard} ]];then
		app_request_body=$(echo ${app_request_body} | sed 's/app_y_axis=//g')
		app_dashboard="${app_request_body}"
	else	
		app_request_body=$(echo ${app_request_body} | sed 's/app_y_axis=//g')
		app_dashboard="${app_dashboard},${app_request_body}"
  fi		

	done

cat <<EOF >> /tmp/${stack_name}_${date_time}
app_y_axis_value=${app_y_axis}
EOF
    
   echo "$app_dashboard"
}

# Create ES dashboard metrics json
get_es_dashboard_body()
{
    
	node_names=$1
	stack_name=$2
	es_y_axis=$3
  es_dashboard=""
	nodes=$(echo $node_names | tr "," "\n")

	for node_name in $nodes
	do

	es_y_axis=$(increment $es_y_axis 20)

es_request_body=$(cat <<-END
{ 
              "type": "query_value",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Unassigned shards ($node_name)",
              "title": "Unassigned shards ($node_name)",
              "height": 7,
              "width": 20,
              "timeframe": "${past_minutes}",
              "y": es_y_axis=$(increment $es_y_axis 1),
              "x": 2,
              "tile_def":{
                "viz":"query_value",
                "requests":[{
                            "q": "avg:elasticsearch.unassigned_shards{host:$node_name}",
                            "aggregator": "avg",
                            "conditional_formats": [
                              {
                                "invert": false,
                                "comparator": ">",
                                "value": 1,
                                "palette": "white_on_red"
                              },
                              {
                                "invert": false,
                                "comparator": "<=",
                                "value": 0,
                                "palette": "white_on_green"
                              }
                            ]
                          }
                         ],
                 "precision": 2,
                 "autoscale": true,
                 "custom_unit": null,
                 "text_align": "left"
            }
          },
          { 
              "type": "query_value",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "ES nodes ($node_name)",
              "title": "ES nodes ($node_name)",
              "height": 7,
              "width": 16,
              "timeframe": "${past_minutes}",
              "y": es_y_axis=$(increment $es_y_axis 1),
              "x": 25,
              "tile_def":{
                "viz":"query_value",
                "requests":[
                          {
                            "q": "avg:elasticsearch.number_of_nodes{host:$node_name}",
                            "aggregator": "avg",
                            "conditional_formats": [
                              {
                                "invert": false,
                                "comparator": "<=",
                                "value": 2,
                                "palette": "white_on_red"
                              },
                              {
                                "invert": false,
                                "comparator": ">",
                                "value": 2,
                                "palette": "white_on_yellow"
                              },
                              {
                                "invert": false,
                                "comparator": ">",
                                "value": 3,
                                "palette": "white_on_green"
                              }
                           ]
                          }
                         ],
                      "precision": 2,
                      "autoscale": true,
                      "custom_unit": null,
                      "text_align": "left"
            }
          },
          { 
              "type": "query_value",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elastcisearch documents count ($node_name)",
              "title": "Elastcisearch documents count ($node_name)",
              "height": 10,
              "width": 26,
              "timeframe": "${past_minutes}",
              "y": es_y_axis=$(increment $es_y_axis 1),
              "x": 45,
              "tile_def":{
                "viz":"query_value",
                "requests":[ {
                            "q": "avg:elasticsearch.docs.count{host:$node_name}",
                            "aggregator": "avg",
                            "conditional_formats": [
                              {
                                "invert": false,
                                "comparator": ">=",
                                "value": 0,
                                "palette": "white_on_green"
                              }
                            ]
                          }
                         ],
                 "precision": 0,
                 "autoscale": false,
                 "custom_unit": "docs",
                 "text_align": "left"
            }
          },
          { 
              "type": "query_value",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elastcisearch deleted ($node_name)",
              "title": "Elastcisearch deleted ($node_name)",
              "height": 10,
              "width": 26,
              "timeframe": "${past_minutes}",
              "y": es_y_axis=$(increment $es_y_axis 1),
              "x": 75,
              "tile_def":{
                "viz":"query_value",
                "requests":[ 
                             {
                                "q": "avg:elasticsearch.docs.deleted{host:$node_name}",
                                "aggregator": "avg",
                                "conditional_formats": [
                                  {
                                    "invert": false,
                                    "comparator": ">=",
                                    "value": 0,
                                    "palette": "white_on_yellow"
                                  }
                                ]
                              }
                         ],
                 "precision": 0,
                 "autoscale": false,
                 "custom_unit": "docs",
                 "text_align": "left"
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elasticsearch process open_fd ($node_name)",
              "title": "Elasticsearch process open_fd ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 22),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                              "q": "avg:elasticsearch.process.open_fd{host:$node_name}",
                              "type": "line",
                              "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elasticsearch refresh growth (per second) ($node_name)",
              "title": "Elasticsearch refresh growth (per second) ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 22),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                                "q": "rate(avg:elasticsearch.refresh.total{host:$node_name})",
                                "type": "line",
                                "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elasticsearch refresh growth (per second) ($node_name)",
              "title": "Elasticsearch refresh growth (per second) ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 42),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                                  "q": "rate(avg:elasticsearch.search.fetch.time{host:$node_name}), rate(avg:elasticsearch.search.query.time{host:$node_name})",
                                  "type": "area",
                                  "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elasticsearch document count growth (per second) ($node_name)",
              "title": "Elasticsearch document count growth (per second) $node_name",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 42),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                                  "q": "rate(avg:elasticsearch.docs.count{host:$node_name})",
                                  "type": "area",
                                  "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Elasticsearch indexing time ($node_name)",
              "title": "Elasticsearch indexing time ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 62),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                                  "q": "rate(avg:elasticsearch.indexing.index.time{host:$node_name})",
                                  "type": "area",
                                  "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "JVM memory heap used ($node_name)",
              "title": "JVM memory heap used ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "1h",
              "y": es_y_axis=$(increment $es_y_axis 62),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[ 
                            {
                                  "q": "sum:jvm.mem.heap_used{host:$node_name} by {host}",
                                  "type": "area",
                                  "conditional_formats": []
                            }
                         ],
                 "autoscale": true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "CPU ($node_name)",
              "title": "CPU ($node_name)",
              "height": $height,
              "width": 100,
              "timeframe": "${past_hour}",
              "y": es_y_axis=$(increment $es_y_axis 82),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:system.cpu.user{host:$node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.system{host:$node_name}",
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.idle{host:$node_name}",
                          "type": "line"
                      }                      
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Disk ($node_name)",
              "title": "Disk ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": es_y_axis=$(increment $es_y_axis 102),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:system.disk.used{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:system.disk.free{host:$node_name}",
                        "type": "line"
                      },                      
                      {
                        "q": "avg:system.disk.total{host:$node_name}",
                        "type": "line"
                      },  
                      {
                        "q": "avg:system.disk.in_use{host:$node_name}",
                        "type": "line"
                      }                                                   
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Memory ($node_name)",
              "title": "Memory ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": es_y_axis=$(increment $es_y_axis 102),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                           {
                              "q": "avg:system.mem.used{host:$node_name}",
                              "aggregator": "avg",
                              "conditional_formats": [],
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.free{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.total{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.usable{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.cached{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.slab{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.shared{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.buffered{host:$node_name}",
                              "type": "line"
                            }
                ],
                "autoscale":true
            }
          }
END
)
  es_y_axis=$(increment $es_y_axis 100)
	if [[ -z ${es_dashboard} ]];then
		es_request_body=$(echo ${es_request_body} | sed 's/es_y_axis=//g')
		es_dashboard="${es_request_body}"
	else	
		es_request_body=$(echo ${es_request_body} | sed 's/es_y_axis=//g')
		es_dashboard="${es_dashboard},${es_request_body}"
    fi		

	done

cat <<EOF >> /tmp/${stack_name}_${date_time}
es_y_axis_value=${es_y_axis}
EOF
    
   echo "$es_dashboard"
}


# Create Worker dashboard metrics json
get_worker_dashboard_body()
{
    
	node_names=$1
	stack_name=$2
	worker_y_axis=$3
  worker_dashboard=""
	nodes=$(echo $node_names | tr "," "\n")

	for node_name in $nodes
	do

	worker_y_axis=$(increment $worker_y_axis 20)

worker_request_body=$(cat <<-END
{ 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "CPU ($node_name)",
              "title": "CPU ($node_name)",
              "height": $height,
              "width": 100,
              "timeframe": "${past_hour}",
              "y": worker_y_axis=$(increment $worker_y_axis 0),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:system.cpu.user{host:$node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.system{host:$node_name}",
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.idle{host:$node_name}",
                          "type": "line"
                      }                      
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Disk ($node_name)",
              "title": "Disk ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": worker_y_axis=$(increment $worker_y_axis 22),
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:system.disk.used{host:$node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:system.disk.free{host:$node_name}",
                        "type": "line"
                      },                      
                      {
                        "q": "avg:system.disk.total{host:$node_name}",
                        "type": "line"
                      },  
                      {
                        "q": "avg:system.disk.in_use{host:$node_name}",
                        "type": "line"
                      }                                                   
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Memory ($node_name)",
              "title": "Memory ($node_name)",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": worker_y_axis=$(increment $worker_y_axis 22),
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                           {
                              "q": "avg:system.mem.used{host:$node_name}",
                              "aggregator": "avg",
                              "conditional_formats": [],
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.free{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.total{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.usable{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.cached{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.slab{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.shared{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.buffered{host:$node_name}",
                              "type": "line"
                            }
                ],
                "autoscale":true
            }
}
END
)
  worker_y_axis=$(increment $worker_y_axis 20)
	if [[ -z ${worker_dashboard} ]];then
		worker_request_body=$(echo ${worker_request_body} | sed 's/worker_y_axis=//g')
		worker_dashboard="${worker_request_body}"
	else	
		worker_request_body=$(echo ${worker_request_body} | sed 's/worker_y_axis=//g')
		worker_dashboard="${worker_dashboard},${worker_request_body}"
    fi		

	done

cat <<EOF >> /tmp/${stack_name}_${date_time}
worker_y_axis_value=${worker_y_axis}
EOF
    
   echo "$worker_dashboard"
}


# Call create dashboard methods
create_datadog_dashboard()
{ 
  dashboard_id=""
	environment=$1
	stack_name=$2
	bastion_node_name=$3
	app_node_name=$4
	es_node_name=$5
	worker_node_name=$6
  infrastructure_version=$7
	dashboard_title="${stack_name^}-${environment}"

  	if [[ ${environment} == "prod" ]];then
  		names_array=$(echo $stack_name | tr "-" "\n")
  		name=$(echo $names_array | awk '{print $1}')
  		dashboard_title="${name^}"
  	fi  

    if [[ ! -z ${app_node_name} ]];then
  	  app_request_body=$(get_app_dashboard_body $app_node_name $stack_name 22)
  	  app_last_y_axis=$(cat /tmp/${stack_name}_${date_time} |  grep app_y_axis_value | awk -F "=" '{print $2}')
  	  merged_request_body=${app_request_body}
    fi

    if [[ ! -z ${es_node_name} ]];then
  	  es_request_body=$(get_es_dashboard_body $es_node_name $stack_name $app_last_y_axis)
  	  es_last_y_axis=$(cat /tmp/${stack_name}_${date_time} | grep es_y_axis_value | awk -F "=" '{print $2}')
  	  merged_request_body="${merged_request_body},${es_request_body}"
    fi
    
    if [[ ! -z ${worker_node_name} ]];then
  	  worker_request_body=$(get_worker_dashboard_body $worker_node_name $stack_name $es_last_y_axis)
  	  merged_request_body="${merged_request_body},${worker_request_body}"
    fi
        	
  	echo "dashboard_title : $dashboard_title"

    count=$(aws s3 ls s3://${BUCKET_NAME}/datadog/${infrastructure_version}/${environment}/${stack_name}/dashboard.json | wc -l)
    if [ $count -gt 0 ]
    then
     aws s3 cp s3://${BUCKET_NAME}/datadog/${infrastructure_version}/${environment}/${stack_name}/dashboard.json /tmp/existing_${stack_name}_${date_time}.json
     dashboard_id=$(cat /tmp/existing_${stack_name}_${date_time}.json | jq -r .dashboard_id)
     echo "existing dashboard id : ${dashboard_id}"
    fi


request_body=$(cat <<EOF
{   
        "width": 1024,
        "height": 1024,
        "board_title": "${dashboard_title}",
        "widgets": [
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Bastion CPU",
              "title": "Bastion CPU",
              "height": $height,
              "width": 100,
              "timeframe": "${past_hour}",
              "y": 2,
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                          "q": "avg:system.cpu.user{host:$bastion_node_name}",
                          "aggregator": "avg",
                          "conditional_formats": [],
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.system{host:$bastion_node_name}",
                          "type": "line"
                      },
                      {
                          "q": "avg:system.cpu.idle{host:$bastion_node_name}",
                          "type": "line"
                      }                      
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Bastion Disk",
              "title": "Bastion Disk",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": 22,
              "x": 2,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                      {
                        "q": "avg:system.disk.used{host:$bastion_node_name}",
                        "aggregator": "avg",
                        "conditional_formats": [],
                        "type": "line"
                      },
                      {
                        "q": "avg:system.disk.free{host:$bastion_node_name}",
                        "type": "line"
                      },                      
                      {
                        "q": "avg:system.disk.total{host:$bastion_node_name}",
                        "type": "line"
                      },
                      {
                        "q": "avg:system.disk.in_use{host:$bastion_node_name}",
                        "type": "line"
                      }                                                   
                ],
                "autoscale":true
            }
          },
          { 
              "type": "timeseries",
              "title": true,
              "title_size": 16,
              "title_align": "left",
              "title_text": "Bastion Memory",
              "title": "Bastion Memory",
              "height": $height,
              "width": $width,
              "timeframe": "${past_hour}",
              "y": 22,
              "x": 54,
              "tile_def":{
                "viz":"timeseries",
                "requests":[
                           {
                              "q": "avg:system.mem.used{host:$bastion_node_name}",
                              "aggregator": "avg",
                              "conditional_formats": [],
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.free{host:$bastion_node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.total{host:$bastion_node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.usable{host:$bastion_node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.cached{host:$bastion_node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.slab{host:$bastion_node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.shared{host:$node_name}",
                              "type": "line"
                            },
                            {
                              "q": "avg:system.mem.buffered{host:$bastion_node_name}",
                              "type": "line"
                            }
                ],
                "autoscale":true
            }
          },
          ${merged_request_body}
        ]
    }
EOF
)

if [[ -z "${dashboard_id}" ]] || [[ "${dashboard_id}" == "null" ]] ;then
	echo "Create new dashboard"
	res=$(curl -X POST -H "Content-type: application/json" -d "$request_body" "https://app.datadoghq.com/api/v1/screen?api_key=${DATADOG_APIKEY}&application_key=${DATADOG_APPKEY}")
  board_id=$(echo $res | jq .id)
  echo "board_id : ${board_id}"
  cat <<EOF >> /tmp/datadog_${stack_name}_${date_time}.json
{
  "dasboard_name" : "${dashboard_title}",
  "dashboard_id" : "${board_id}"
}
EOF
aws s3 cp /tmp/datadog_${stack_name}_${date_time}.json s3://${BUCKET_NAME}/datadog/${infrastructure_version}/${environment}/${stack_name}/dashboard.json
else
  echo "Updating dashboard $dashboard_id"
  res=$(curl -X PUT -H "Content-type: application/json" -d "$request_body"  "https://app.datadoghq.com/api/v1/screen/${dashboard_id}?api_key=${DATADOG_APIKEY}&application_key=${DATADOG_APPKEY}")
  board_id=$(echo $res | jq .id)
  echo "board_id : ${board_id}"
fi  

rm -rf /tmp/datadog_${stack_name}_${date_time}.json
rm -rf /tmp/cat /tmp/${stack_name}_${date_time}
rm -rf /tmp/existing_${stack_name}_${date_time}.json
}

get_instances()
{
aws_region=$1
response=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=bastion" --region ${aws_region} --query "Reservations[*].Instances[*].Tags[]")

length=$(echo $response | jq '. | length')

COUNTER=0

while [  $COUNTER -lt $length ]; do 

    infrastructure_version=$(echo $response | jq  -r ".[$COUNTER][] | select(.Key==\"infrastructure-version\") .Value")

    if version_gt ${infrastructure_version:1} "1.1.0"; then
     
     stack_identifier=$(echo $response | jq  -r ".[$COUNTER][] | select(.Key==\"stack-identifier\") .Value")
     environment=$(echo $response | jq  -r ".[$COUNTER][] | select(.Key==\"environment\") .Value")
     echo $stack_identifier

     bastion_node_name=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=bastion" "Name=tag:stack-identifier,Values=${stack_identifier}" --region ${aws_region}  --query "Reservations[0].Instances[0].{name: Tags[?Key=='Name'] | [0].Value}" --output text)
     es_node_names=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=elasticsearch" "Name=tag:stack-identifier,Values=${stack_identifier}" --region ${aws_region}  --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value}" --output text) 
     worker_node_names=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=worker" "Name=tag:stack-identifier,Values=${stack_identifier}" --region ${aws_region}  --query "Reservations[].Instances[].{name: Tags[?Key=='Name'] | [0].Value}" --output text) 
     app_node_names=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=nuxeo" "Name=tag:stack-identifier,Values=${stack_identifier}" --region ${aws_region}  --query "Reservations[].Instances[].{name: Tags[?Key=='Name'] | [0].Value}" --output text)     
     
     es_node_names=$(echo ${es_node_names} | sed  's/\s/,/g')
     worker_node_names=$(echo ${worker_node_names} | sed  's/\s/,/g')
     app_node_names=$(echo ${app_node_names} | sed  's/\s/,/g')

     create_datadog_dashboard ${environment} ${stack_identifier} "${bastion_node_name}" "${app_node_names}" "${es_node_names}" "${worker_node_names}" "${infrastructure_version}"

    fi

    let COUNTER=COUNTER+1
done

}

function create_datadog_dashboard_for_region()
{
  declare -a regionNames=('us-east-1' 'eu-west-1' 'eu-west-2' 'eu-central-1' 'us-east-2' 'us-west-1' 'us-west-2' 'ap-south-1' 'ap-northeast-1' 'ap-northeast-2' 'ap-southeast-1' 'ap-southeast-2' 'sa-east-1');
  for i in "${regionNames[@]}"
  do
  region=$i
  get_instances ${region}
  done
}

create_datadog_dashboard_for_region