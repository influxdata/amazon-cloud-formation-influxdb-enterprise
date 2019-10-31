#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/enterprise/releases/influxdb-meta-$1_c$1.x86_64.rpm" --output "influxdb-meta-$1_c$1.x86_64.rpm"
sudo yum -y -q localinstall "influxdb-meta-$1_c$1.x86_64.rpm"
rm "influxdb-meta-$1_c$1.x86_64.rpm"
sudo systemctl stop influxdb-meta.service
sudo systemctl disable influxdb-meta.service
sudo mv /etc/influxdb/influxdb-meta.conf /etc/influxdb/influxdb-meta.conf.original
sudo mv /tmp/config/influxdb-meta.conf /etc/influxdb/influxdb-meta.conf
sudo chown -R influxdb:influxdb /etc/influxdb/influxdb-meta.conf
