#!/usr/bin/env bash

set -euxo pipefail

readonly version="${1}"
readonly type="${2}"

case "${type}" in
    "data")
        download_path="enterprise"
        package_name="influxdb-data"
        package_version="${version}_c${version}"
        service_name="influxdb"
        config_filename="influxdb.conf";;
    "meta")
        download_path="enterprise"
        package_name="influxdb-meta"
        package_version="${version}_c${version}"
        service_name="influxdb-meta"
        config_filename="influxdb-meta.conf";;
    "monitor")
        download_path="influxdb"
        package_name="influxdb"
        package_version="${version}"
        service_name="influxdb"
        config_filename="influxdb.conf";;
esac

curl -s "https://dl.influxdata.com/${download_path}/releases/${package_name}-${package_version}.x86_64.rpm" --output "${package_name}-${package_version}.x86_64.rpm"
sudo yum -y -q localinstall "${package_name}-${package_version}.x86_64.rpm"
rm "${package_name}-${package_version}.x86_64.rpm"
sudo systemctl stop "${service_name}.service"
sudo systemctl disable "${service_name}.service"
cat "/tmp/config/influxdb.conf" "/etc/influxdb/${config_filename}" > "${config_filename}.tmp"
sudo rm "/etc/influxdb/${config_filename}"
sudo mv "${config_filename}.tmp" "/etc/influxdb/${config_filename}"
sudo chown -R influxdb:influxdb "/etc/influxdb/${config_filename}"
