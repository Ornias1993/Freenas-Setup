#!/usr/local/bin/bash
# This script installs the current release of InfluxDB

#init jail
initblueprint "$1"

# Initialise defaults

# Mount and configure proper configuration location
cp -rf "${includes_dir}/influxd.conf" "/mnt/${global_dataset_config}/${1}/influxd.conf"
iocage exec "${1}" mkdir -p /config/db/data /config/db/meta /config/db/wal
iocage exec "${1}" chown -R influxd:influxd /config/db
iocage exec "${1}" sysrc influxd_conf="/config/influxd.conf"
iocage exec "${1}" sysrc influxd_enable="YES"

# Start influxdb and wait for it to startup
iocage exec "${1}" service influxd start
sleep 15

exitblueprint "$1" "You may connect InfluxDB plugins to the InfluxDB jail at http://${jail_ip}:8086."
