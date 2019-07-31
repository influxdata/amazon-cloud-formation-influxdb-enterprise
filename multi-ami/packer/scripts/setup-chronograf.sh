#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/chronograf/releases/chronograf-$1.x86_64.rpm" --output "chronograf-$1.x86_64.rpm"
sudo yum -y -q localinstall "chronograf-$1.x86_64.rpm"
rm "chronograf-$1.x86_64.rpm"
sudo rm /etc/init.d/chronograf
sudo cp -f /usr/lib/chronograf/scripts/chronograf.service /usr/lib/systemd/system/chronograf.service
sudo systemctl daemon-reload || true
