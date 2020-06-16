#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/telegraf/releases/telegraf-$1-1.x86_64.rpm" --output "telegraf-$1-1.x86_64.rpm"
sudo yum -y -q localinstall "telegraf-$1-1.x86_64.rpm"
rm "telegraf-$1-1.x86_64.rpm"
sudo systemctl stop telegraf.service
sudo systemctl disable telegraf.service
sudo mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.original
sudo mv "/tmp/config/telegraf-$2.conf" /etc/telegraf/telegraf.conf
sudo chown -R telegraf:telegraf /etc/telegraf/telegraf.conf
