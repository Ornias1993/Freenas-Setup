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

# Make sure DB_PATH is empty -- if not, InfluxDB will choke
if [ "$(ls -A "/mnt/${global_dataset_config}/${JAIL_NAME}")" ]; then
	echo "Reinstall of influxdb detected... Continuing"
	REINSTALL="true"
fi

iocage exec "${JAIL_NAME}" chown -R 907:907 /var/db/influxdb

# Install includes fstab
iocage exec "${JAIL_NAME}" mkdir -p /mnt/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

#####
# 
# Install influxdb
#
#####

iocage exec "${JAIL_NAME}" sysrc influxd_enable="YES"

# Copy and edit pre-written config files
echo "Copying default config file"
iocage exec "${JAIL_NAME}" cp -f /mnt/includes/influxdb.conf /usr/local/etc/

# Start influxdb and wait for it to startup
iocage exec "${JAIL_NAME}" service influxd start
sleep 30

if [ "${REINSTALL}" == "true" ]; then
	echo "Reinstall detected, skipping generation of new config and database"
else
	
	# Create database and restart
    iocage exec "${JAIL_NAME}" curl -i -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE $DATABASE"
	iocage exec "${JAIL_NAME}" service influxd restart
fi
	
# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

# Done!
echo "Installation complete!"
echo "Your may connect InfluxDB plugins to the InfluxDB jail at http://${JAIL_IP}:8086."

if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please use your old database."
else
	echo "Database Information"
	echo "--------------------"
	echo "Database = ${DATABASE} at http://${JAIL_IP}:8086."
	fi
echo ""
