#!/usr/bin/env bash

set -euxo pipefail

readonly config_name="${3:-influxdb}"

curl -s "https://dl.influxdata.com/enterprise/releases/${1}-${2}.x86_64.rpm" --output "${1}-${2}.x86_64.rpm"
sudo yum -y -q localinstall "${1}-${2}.x86_64.rpm"
rm "${1}-${2}.x86_64.rpm"
sudo systemctl stop "${config_name}.service"
sudo systemctl disable "${config_name}.service"
cat "/tmp/config/influxdb.conf" "/etc/influxdb/${config_name}.conf" > "${config_name}.conf.tmp"
sudo rm "/etc/influxdb/${config_name}.conf"
sudo mv "${config_name}.conf.tmp" "/etc/influxdb/${config_name}.conf"
sudo chown -R influxdb:influxdb "/etc/influxdb/${config_name}.conf"
