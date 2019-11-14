#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/influxdb/releases/influxdb-$1.x86_64.rpm" --output "influxdb-$1.x86_64.rpm"
sudo yum -y -q localinstall "influxdb-$1.x86_64.rpm"
rm "influxdb-$1.x86_64.rpm"
sudo systemctl stop influxdb.service
sudo systemctl disable influxdb.service
sudo mv /etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf.original
sudo mv /tmp/config/influxdb-monitor.conf /etc/influxdb/influxdb.conf
sudo chown -R influxdb:influxdb /etc/influxdb/influxdb.conf
