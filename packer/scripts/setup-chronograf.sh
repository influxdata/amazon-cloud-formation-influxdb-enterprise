#!/usr/bin/env bash

set -euxo pipefail

curl -s "https://dl.influxdata.com/chronograf/releases/chronograf-${1}.x86_64.rpm" --output "chronograf-${1}.x86_64.rpm"
sudo yum -y -q localinstall "chronograf-${1}.x86_64.rpm"
rm "chronograf-${1}.x86_64.rpm"
sudo systemctl stop chronograf.service
sudo systemctl disable chronograf.service
