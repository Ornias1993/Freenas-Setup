#!/usr/local/bin/bash
# This file contains the install script for unifi-controller & unifi-poller

# Initialize variables
JAIL_NAME="unifi"
JAIL_IP="$(sed 's|\(.*\)/.*|\1|' <<<"${influxdb_ip4_addr}" )"
DB_JAIL="${unifi_db_jail}"
DB_NAME="${unifi_db_name:-unifi}"
DB_USER="${unifi_db_user:-unifipoller}"
DB_PASS="${unifi_db_password:-unifipoller}"
INCLUDES_PATH="${SCRIPT_DIR}/jails/unifi/includes"

# Check if influxdb container exists, create unifi database if it does, error if it is not.
echo "Checking if the database jail and database exist..."
if [ -d "/mnt/${global_dataset_iocage}/jails/${DB_JAIL}/root/var/db/influxdb" ]; then
  DB_EXISTING=$(iocage exec "${DB_JAIL}" curl -G http://localhost:8086/query --data-urlencode 'q=SHOW DATABASES' | jq '.results [] | .series [] | .values []' | grep "$DB_NAME" | sed 's/"//g' | sed 's/^ *//g')
  if [[ "$DB_NAME" == "$DB_EXISTING" ]]; then
    echo "${DB_JAIL} jail with database ${DB_NAME} already exists. Skipping database creation... "
  else
    echo "${DB_JAIL} jail exists, but database ${DB_NAME} does not. Creating database ${DB_NAME}."
    iocage exec "${DB_JAIL}" "curl -XPOST -u ${DB_USER}:${DB_PASS} http://localhost:8086/query --data-urlencode 'q=CREATE DATABASE ${DB_NAME}'"
    echo "Database ${DB_NAME} created with username ${DB_USER} with password ${DB_PASS}."
  fi
else
  echo "Influx jail does not exist. Unifi-Poller requires Influxdb jail. Please install the Influxdb jail."
  exit 1
fi

# Download Unifi-Poller and verify checksum
FILE="unifi-poller-2.0.0_760.amd64.txz"
FILE_VERSION="v2.0.0"
echo "Downloading Unifi-Poller and verifying checksum..."
iocage exec "${JAIL_NAME}" "fetch -o /tmp --no-verify-peer https://github.com/unifi-poller/unifi-poller/releases/download/${FILE_VERSION}/${FILE} https://github.com/unifi-poller/unifi-poller/releases/download/${FILE_VERSION}/checksums.sha256.txt" 
iocage exec "${JAIL_NAME}" "grep unifi-poller-2.0.0_760.amd64.txz /tmp/checksums.sha256.txt > /tmp/unifi-poller-2.0.0_760.amd64.sha256"
if ! iocage exec "${JAIL_NAME}" "cd /tmp && shasum -a 256 -c /tmp/unifi-poller-2.0.0_760.amd64.sha256"; then
  echo "Download failed checksum. Exiting..."
  exit 1
fi
echo "Download complete, installing Unifi-Poller..."

# Install downloaded package and enable 
iocage exec "${JAIL_NAME}" pkg install /tmp/unifi-poller-2.0.0_760.amd64.txz
iocage exec "${JAIL_NAME}" mv /usr/local/etc/rc.d/unifi-poller /usr/local/etc/rc.d/unifi_poller
iocage exec "${JAIL_NAME}" sysrc unifi_enable=YES
iocage exec "${JAIL_NAME}" sysrc unifi_poller_enable=YES

# Mount includes and copy config files
echo "Copying config file..."
iocage exec "${JAIL_NAME}" mkdir -p /mnt/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0
iocage exec "${JAIL_NAME}" cp /mnt/includes/up.* /usr/local/etc/unifi-poller/

# Start Unifi Controller and Unifi-Poller
echo "Starting Unifi-Controller and Unifi-Poller..."
iocage exec "${JAIL_NAME}" service unifi start
iocage exec "${JAIL_NAME}" service unifi_poller start

echo "Installation complete!"
echo "Unifi Controller is accessible at ${JAIL_IP}:8443."
echo "Please login to the Unifi Controller and add a read-only user (default: unifipoller)."
echo "In Grafana, add Unifi-Poller as a data source."