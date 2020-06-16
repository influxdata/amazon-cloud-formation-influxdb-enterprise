#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/kapacitor/releases/kapacitor-$1-1.x86_64.rpm" --output "kapacitor-$1-1.x86_64.rpm"
sudo yum -y -q localinstall "kapacitor-$1-1.x86_64.rpm"
rm "kapacitor-$1-1.x86_64.rpm"
sudo systemctl stop kapacitor.service
sudo systemctl disable kapacitor.service
sudo mv /etc/kapacitor/kapacitor-monitor.conf /etc/kapacitor/kapacitor-monitor.conf
sudo chown -R kapacitor:kapacitor /etc/kapacitor/kapacitor.conf
