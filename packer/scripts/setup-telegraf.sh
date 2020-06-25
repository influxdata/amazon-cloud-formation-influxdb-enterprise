#!/usr/bin/env bash

set -euxo pipefail

readonly version="${1}"
readonly type="${2}"

curl -s "https://dl.influxdata.com/telegraf/releases/telegraf-${version}-1.x86_64.rpm" --output "telegraf-${version}-1.x86_64.rpm"
sudo yum -y -q localinstall "telegraf-${version}-1.x86_64.rpm"
rm "telegraf-${version}-1.x86_64.rpm"
sudo systemctl stop telegraf.service
sudo systemctl disable telegraf.service
sudo mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.original
sudo mv "/tmp/config/telegraf-${type}.conf" /etc/telegraf/telegraf.conf
sudo chown -R telegraf:telegraf /etc/telegraf/telegraf.conf
