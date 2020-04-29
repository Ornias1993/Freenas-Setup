#!/usr/local/bin/bash
# This file contains the install script for unifi-controller & unifi-poller

# Initialize variables
JAIL_NAME="unifi"
# shellcheck disable=SC2154
JAIL_IP="${unifi_ip4_addr%/*}"
# shellcheck disable=SC2154
DB_IP="${influxdb_ip4_addr%/*}"
# shellcheck disable=SC2154
DB_JAIL="${unifi_db_jail}"
# shellcheck disable=SC2154
DB_NAME="${unifi_up_db_name:-unifi}"
# shellcheck disable=SC2154
DB_USER="${unifi_up_db_user}"
# shellcheck disable=SC2154
DB_PASS="${unifi_up_db_password}"
# shellcheck disable=SC2154
UP_USER="${unifi_up_user}"
# shellcheck disable=SC2154
UP_PASS="${unifi_up_password}"
INCLUDES_PATH="${SCRIPT_DIR}/jails/unifi/includes"

# Enable persistent Unifi Controller data
iocage exec "${JAIL_NAME}" mkdir -p /config/controller/mongodb
iocage exec "${JAIL_NAME}" cp -Rp /usr/local/share/java/unifi /config/controller
iocage exec "${JAIL_NAME}" chown -R mongodb:mongodb /config/controller/mongodb
# shellcheck disable=SC2154
cp "${INCLUDES_PATH}"/mongodb.conf /mnt/"${global_dataset_iocage}"/jails/"${JAIL_NAME}"/root/usr/local/etc
# shellcheck disable=SC2154
cp "${INCLUDES_PATH}"/rc/mongod /mnt/"${global_dataset_iocage}"/jails/"${JAIL_NAME}"/root/usr/local/etc/rc.d/
# shellcheck disable=SC2154
cp "${INCLUDES_PATH}"/rc/unifi /mnt/"${global_dataset_iocage}"/jails/"${JAIL_NAME}"/root/usr/local/etc/rc.d/
iocage exec "${JAIL_NAME}" sysrc unifi_enable=YES
iocage exec "${JAIL_NAME}" service unifi start

# shellcheck disable=SC2154
if [[ ! "${unifi_unifi_poller}" ]]; then
  echo "Installation complete!"
  echo "Unifi Controller is accessible at https://${JAIL_IP}:8443."
else
  # Check if influxdb container exists, create unifi database if it does, error if it is not.
  echo "Checking if the database jail and database exist..."
  if [[ -d /mnt/"${global_dataset_iocage}"/jails/"${DB_JAIL}" ]]; then
    DB_EXISTING=$(iocage exec "${DB_JAIL}" curl -G http://localhost:8086/query --data-urlencode 'q=SHOW DATABASES' | jq '.results [] | .series [] | .values []' | grep "$DB_NAME" | sed 's/"//g' | sed 's/^ *//g')
    if [[ "$DB_NAME" == "$DB_EXISTING" ]]; then
      echo "${DB_JAIL} jail with database ${DB_NAME} already exists. Skipping database creation... "
    else
      echo "${DB_JAIL} jail exists, but database ${DB_NAME} does not. Creating database ${DB_NAME}."
      if [[ -z "${DB_USER}" ]] || [[ -z "${DB_PASS}" ]]; then
        echo "Database username and password not provided. Cannot create database without credentials. Exiting..."
        exit 1
      else
        iocage exec "${DB_JAIL}" "curl -XPOST -u ${DB_USER}:${DB_PASS} http://localhost:8086/query --data-urlencode 'q=CREATE DATABASE ${DB_NAME}'"
        echo "Database ${DB_NAME} created with username ${DB_USER} with password ${DB_PASS}."
      fi
    fi
  else
    echo "Influxdb jail does not exist. Unifi-Poller requires Influxdb jail. Please install the Influxdb jail."
    exit 1
  fi

  # Download and install Unifi-Poller
  FILE_NAME=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .name")
  DOWNLOAD=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .browser_download_url")
  iocage exec "${JAIL_NAME}" fetch -o /config "${DOWNLOAD}"

  # Install downloaded Unifi-Poller package, configure and enable 
  iocage exec "${JAIL_NAME}" pkg install -qy /config/"${FILE_NAME}"
  # shellcheck disable=SC2154
  cp "${INCLUDES_PATH}"/up.conf /mnt/"${global_dataset_config}"/"${JAIL_NAME}"
  # shellcheck disable=SC2154
  cp "${INCLUDES_PATH}"/up.conf.example /mnt/"${global_dataset_config}"/"${JAIL_NAME}"
  # shellcheck disable=SC2154
  cp "${INCLUDES_PATH}"/rc/unifi_poller /mnt/"${global_dataset_iocage}"/jails/"${JAIL_NAME}"/root/usr/local/etc/rc.d/unifi_poller
  iocage exec "${JAIL_NAME}" sed -i '' "s|influxdbuser|${DB_USER}|" /config/up.conf
  iocage exec "${JAIL_NAME}" sed -i '' "s|influxdbpass|${DB_PASS}|" /config/up.conf
  iocage exec "${JAIL_NAME}" sed -i '' "s|unifidb|${DB_NAME}|" /config/up.conf
  iocage exec "${JAIL_NAME}" sed -i '' "s|unifiuser|${UP_USER}|" /config/up.conf
  iocage exec "${JAIL_NAME}" sed -i '' "s|unifipassword|${UP_PASS}|" /config/up.conf
  iocage exec "${JAIL_NAME}" sed -i '' "s|dbip|http://${DB_IP}:8086|" /config/up.conf


  iocage exec "${JAIL_NAME}" sysrc unifi_poller_enable=YES
  iocage exec "${JAIL_NAME}" service unifi_poller start

  echo "Installation complete!"
  echo "Unifi Controller is accessible at https://${JAIL_IP}:8443."
  echo "Please login to the Unifi Controller and add ${UP_USER} as a read-only user."
  echo "In Grafana, add Unifi-Poller as a data source."
fi
