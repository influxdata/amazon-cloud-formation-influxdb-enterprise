#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/kapacitor/releases/kapacitor-${1}-1.x86_64.rpm" --output "kapacitor-${1}-1.x86_64.rpm"
sudo yum -y -q localinstall "kapacitor-${1}-1.x86_64.rpm"
rm "kapacitor-${1}-1.x86_64.rpm"
sudo rm -r /etc/init.d/kapacitor
sudo cp /tmp/config/kapacitor.service /usr/lib/systemd/system/kapacitor.service
sudo chown root:root /usr/lib/systemd/system/kapacitor.service
sudo chmod 644 /usr/lib/systemd/system/kapacitor.service
sudo mv /etc/kapacitor/kapacitor.conf /etc/kapacitor/kapacitor.conf.original
sudo mv /tmp/config/kapacitor.conf /etc/kapacitor/
sudo chown -R kapacitor:kapacitor /etc/kapacitor/kapacitor.conf
sudo chown -R kapacitor:kapacitor /var/log/kapacitor
sudo systemctl daemon-reload || true
sudo systemctl disable kapacitor.service
