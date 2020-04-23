#!/usr/local/bin/bash
# This script installs the current release of InfluxDB

#####
# 
# Init and Mounts
#
#####

# Initialise variables
JAIL_NAME="influxdb"
JAIL_IP="$(sed 's|\(.*\)/.*|\1|' <<<"${influxdb_ip4_addr}" )"
INCLUDES_PATH="${SCRIPT_DIR}/jails/influxdb/includes"
DATABASE=${influxdb_database}

# Mount and configure proper configuration location
cp -rf "${INCLUDES_PATH}/influxd.conf" "/mnt/${global_dataset_config}/${JAIL_NAME}/influxd.conf"
iocage exec "${JAIL_NAME}" mkdir -p /config/db/data /config/db/meta /config/db/wal
iocage exec "${JAIL_NAME}" chown -R influxd:influxd /config/db
iocage exec "${JAIL_NAME}" sysrc influxd_conf="/config/influxd.conf"
iocage exec "${JAIL_NAME}" sysrc influxd_enable="YES"

# Start influxdb and wait for it to startup
iocage exec "${JAIL_NAME}" service influxd start
sleep 15

# Create database and restart
if iocage exec "${JAIL_NAME}" curl -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${DATABASE}"; then
  echo "Database created."
else 
  echo "Database creation failed. Please attempt to create the database manually."
  exit 1
fi

# Done!
echo "Installation complete!"
echo "You may connect InfluxDB plugins to the InfluxDB jail at http://${JAIL_IP}:8086."
echo ""
echo "Database Information"
echo "--------------------"
echo "Database = ${DATABASE} at http://${JAIL_IP}:8086."
echo ""