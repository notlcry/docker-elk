#!/bin/bash

echo "create elasticsearch data path"
mkdir -p /opt/es/data/
chown -R 1000:1000 /opt/es/data/

echo "starting elk stack docker containers"
docker-compose up -d
echo "elk stack docker containers finish"

echo "sleep 120s for kibana init"
sleep 120

## add index-pattern for logstash
echo "create index pattern"
curl -XPOST -D- 'http://localhost:5601/api/saved_objects/index-pattern' \
    -H 'Content-Type: application/json' \
    -H 'kbn-version: 7.9.0' \
    -d '{"attributes":{"title":"logstash-*","timeFieldName":"@timestamp"}}'

## modify default lifecycle policy for 90day log rotation
echo "modify logstash lifecycle policy"
curl -XPUT "http://localhost:9200/_ilm/policy/logstash-policy" \
-H 'Content-Type: application/json' \
-d'{  "policy": {    "phases": {      "hot": {        "min_age": "0ms",        "actions": {          "rollover": {            "max_age": "7d",            "max_size": "5gb"          },          "set_priority": {            "priority": null          }        }      },      "delete": {        "min_age": "90d",        "actions": {          "delete": {            "delete_searchable_snapshot": true          }        }      }    }  }}'
