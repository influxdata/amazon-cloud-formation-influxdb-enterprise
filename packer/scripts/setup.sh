#!/usr/bin/env bash

set -euxo pipefail

sudo yum update -y --security
sleep 10

cp /tmp/scripts/* .
sudo chmod +x ./setup-*

# sudo chown -R ec2-user:ec2-user /home/ec2-user/setup-*

case "${PACKER_BUILD_NAME}" in
    "enterprise-data")
        ./setup-influxdb.sh "${INFLUXDB_VERSION}" data
        sleep 5
        ./setup-telegraf.sh "${TELEGRAF_VERSION}" data;;
    "enterprise-meta")
        ./setup-influxdb.sh "${INFLUXDB_VERSION}" meta
        sleep 5
        ./setup-telegraf.sh "${TELEGRAF_VERSION}" meta;;
    "oss-monitor")
        ./setup-influxdb.sh "${INFLUXDB_VERSION}" monitor
        sleep 5
        ./setup-telegraf.sh "${TELEGRAF_VERSION}" monitor
        sleep 5
        ./setup-chronograf.sh "${CHRONOGRAF_VERSION}"
        sleep 5
        ./setup-kapacitor.sh "${KAPACITOR_VERSION}";;
esac

sudo chmod +x ./validate.sh
./validate.sh
rm -r ./*.sh

rm -r /tmp/scripts /tmp/config
rm .ssh/authorized_keys
sudo rm /root/.ssh/authorized_keys
