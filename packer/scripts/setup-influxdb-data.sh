#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/enterprise/releases/influxdb-data-$1_c$1.x86_64.rpm" --output "influxdb-data-$1_c$1.x86_64.rpm"
sudo yum -y -q localinstall "influxdb-data-$1_c$1.x86_64.rpm"
rm "influxdb-data-$1_c$1.x86_64.rpm"
sudo systemctl stop influxdb.service
sudo systemctl disable influxdb.service
cat /tmp/config/influxdb-data.conf /etc/influxdb/influxdb.conf > influxdb.conf.tmp
sudo rm /etc/influxdb/influxdb.conf
sudo mv influxdb.conf.tmp /etc/influxdb/influxdb.conf
sudo chown -R influxdb:influxdb /etc/influxdb/influxdb.conf
