#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/chronograf/releases/chronograf-$1.x86_64.rpm" --output "chronograf-$1.x86_64.rpm"
sudo yum -y -q localinstall "chronograf-$1.x86_64.rpm"
rm "chronograf-$1.x86_64.rpm"
sudo rm -r /etc/init.d/chronograf
sudo cp /tmp/config/chronograf.service /usr/lib/systemd/system/chronograf.service
sudo chown root:root /usr/lib/systemd/system/chronograf.service
sudo chmod 644 /usr/lib/systemd/system/chronograf.service
sudo systemctl daemon-reload || true
sudo systemctl enable chronograf
sudo systemctl disable chronograf
