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
DB_USER=${influxdb_db_user}
DB_PASSWORD=${influxdb_db_password}

# # Check that necessary variables were set 
# if [ -z "${influxdb_ip4_addr}" ]; then
#   echo 'Configuration error: The InfluxDB jail does NOT accept DHCP'
#   echo 'Please reinstall using a fixed IP adress'
#   exit 1
# fi

# Make sure DB_PATH is empty -- if not, InfluxDB will choke

if [ "$(ls -A "/mnt/${global_dataset_config}/${JAIL_NAME}")" ]; then
	echo "Reinstall of influxdb detected... Continuing"
	REINSTALL="true"
fi

# Mount database dataset and set zfs preferences
# createmount ${JAIL_NAME} ${global_dataset_config}/${JAIL_NAME}/db /var/db/influxdb/data
# createmount ${JAIL_NAME} ${global_dataset_config}/${JAIL_NAME}/wal /var/db/influxdb/meta

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
sleep 5s

if [ "${REINSTALL}" == "true" ]; then
	echo "Reinstall detected, skipping generaion of new config and database"
else
	
	# Create database, set username and password
    iocage exec "${JAIL_NAME}" curl -i -XPOST http://${JAIL_IP}:8086/query --data-urlencode 'q=CREATE DATABASE '${DATABASE}''
    iocage exec "${JAIL_NAME}" curl -i -XPOST http://${JAIL_IP}:8086/query --data-urlencode 'q=CREATE USER '${DB_USER}' WITH PASSWORD '${DB_PASSWORD}''
	iocage exec "${JAIL_NAME}" service influxd restart
fi

# Save passwords for later reference
iocage exec "${JAIL_NAME}" echo "${DATABASE} user is ${DB_USER} and the password is ${DB_PASSWORD}" > /root/${JAIL_NAME}_db_password.txt
	
# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

# Done!
echo "Installation complete!"
echo "Your may connect InfluxDB plugins to the InfluxDB jail at http://${JAIL_IP}:8086."

if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please use your old database and account credentials"
else
	echo "Database Information"
	echo "--------------------"
	echo "The ${DATABASE} user is ${DB_USER} and password is ${DB_PASSWORD}"
	fi
echo ""
echo "All passwords are saved in /root/${JAIL_NAME}_db_password.txt"
