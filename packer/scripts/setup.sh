#!/usr/bin/env bash

set -euxo pipefail

sudo yum update -y --security
# while [[ $(pgrep yum | wc -l) -eq 0 ]]; do sleep 10; done

sleep 10
# pkill "$(pgrep yum)"

cp /tmp/scripts/* .
sudo chmod +x ./setup-*
sudo chmod +x ./validate.sh

# sudo chown -R ec2-user:ec2-user /home/ec2-user/setup-*

case "${PACKER_BUILD_NAME}" in
    "enterprise-data")
        ./setup-influxdb.sh influxdb-data "${INFLUXDB_VERSION}_c${INFLUXDB_VERSION}"
        sleep 10
        ./setup-telegraf.sh data "${TELEGRAF_VERSION}";;
    "enterprise-meta")
        ./setup-influxdb.sh influxdb-meta "${INFLUXDB_VERSION}_c${INFLUXDB_VERSION}" influxdb-meta
        sleep 10
        ./setup-telegraf.sh meta "${TELEGRAF_VERSION}";;
    "oss-monitor")
        ./setup-influxdb.sh influxdb "${INFLUXDB_VERSION}"
        sleep 10
        ./setup-telegraf.sh monitor "${TELEGRAF_VERSION}"
        sleep 10
        ./setup-chronograf.sh "${CHRONOGRAF_VERSION}"
        sleep 10
        ./setup-kapacitor.sh "${KAPACITOR_VERSION}";;
esac

sudo chmod +x ./validate.sh
./validate.sh

rm -r /tmp/scripts /tmp/config
rm .ssh/authorized_keys
sudo rm /root/.ssh/authorized_keys
