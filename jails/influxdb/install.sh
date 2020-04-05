#!/usr/local/bin/bash
# This script installs the current release of InfluxDB

#####
# 
# Init and Mounts
#
#####

# Initialise defaults
JAIL_NAME="influxdb"
JAIL_IP="$(sed 's|\(.*\)/.*|\1|' <<<"${influxdb_ip4_addr}" )"
INCLUDES_PATH="${SCRIPT_DIR}/jails/influxdb/includes"
DATABASE=${influxdb_database}

# Enable influxdb
iocage exec "${JAIL_NAME}" sysrc influxd_enable="YES"

# Copy and edit pre-written config files
echo "Copying default config file"
iocage exec ${JAIL_NAME} mkdir -p /usr/local/etc
cp ${INCLUDES_PATH}/influxdb.conf /mnt/${GLOBAL_DATASET_IOCAGE}/jails/${JAIL_NAME}/root/usr/local/etc/

# Start influxdb and wait for it to startup
iocage exec "${JAIL_NAME}" service influxd start
sleep 15

# Create database and restart
iocage exec "${JAIL_NAME}" "curl -i -XPOST http://localhost:8086/query --data-urlencode 'q=CREATE DATABASE ${DATABASE}'"
iocage exec "${JAIL_NAME}" service influxd restart
	
# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

# Done!
echo "Installation complete!"
echo "Your may connect InfluxDB plugins to the InfluxDB jail at http://${JAIL_IP}:8086."
echo ""
echo "Database Information"
echo "--------------------"
echo "Database = ${DATABASE} at http://${JAIL_IP}:8086."
echo ""
echo "Configuration Information"
echo "-------------------------"
echo "Configuration located at /usr/local/etc/influxdb.conf"
echo ""