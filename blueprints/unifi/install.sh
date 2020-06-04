#!/usr/local/bin/bash
# This file contains the install script for unifi-controller & unifi-poller

#init jail
initblueprint "$1"

# Initialize variables
database="${database:-$1}"
database_user="${database_user:-$database}"
poller_user="${poller_user:-$1}"

# Enable persistent Unifi Controller data
iocage exec "${1}" mkdir -p /config/controller/mongodb
iocage exec "${1}" cp -Rp /usr/local/share/java/unifi /config/controller
iocage exec "${1}" chown -R mongodb:mongodb /config/controller/mongodb
cp "${includes_dir}"/mongodb.conf /mnt/"${global_dataset_iocage}"/jails/"${1}"/root/usr/local/etc
cp "${includes_dir}"/rc/mongod.rc /mnt/"${global_dataset_iocage}"/jails/"${1}"/root/usr/local/etc/rc.d/mongod
cp "${includes_dir}"/rc/unifi.rc /mnt/"${global_dataset_iocage}"/jails/"${1}"/root/usr/local/etc/rc.d/unifi
iocage exec "${1}" sysrc unifi_enable=YES
iocage exec "${1}" service unifi start

if [ "${poller}" == "false" ]; then
  echo "Unifi Poller not selected, skipping Unifi Poller installation."
else
	if [ -z "${database_password}" ]; then
	echo "database_password can't be empty"
	exit 1
	fi

	if [ -z "${link_influxdb}" ]; then
	echo "link_influxdb can't be empty"
	exit 1
	fi

	if [ -z "${poller_password}" ]; then
	echo "poller_password can't be empty"
	exit 1
	fi
  # Check if influxdb container exists, create unifi database if it does, error if it is not.
  echo "Installing Unifi Poller..."
  echo "Checking if the database jail and database exist..."
  if [[ -d /mnt/"${global_dataset_iocage}"/jails/"${link_influxdb}" ]]; then
    DB_EXISTING=$(iocage exec "${link_influxdb}" curl -G http://"${link_influxdb_ip4_addr%/*}":8086/query --data-urlencode 'q=SHOW DATABASES' | jq '.results [] | .series [] | .values []' | grep "$database" | sed 's/"//g' | sed 's/^ *//g')
    if [[ "${database}" == "${DB_EXISTING}" ]]; then
      echo "${link_influxdb} jail with database ${database} already exists. Skipping database creation... "
    else
      echo "${link_influxdb} jail exists, but database ${database} does not. Creating database ${database}."
      if [[ -z "${database_password}" ]]; then
        echo "Database password not provided. Cannot create database without credentials. Exiting..."
        exit 1
      else
        # shellcheck disable=SC2027,2086
        iocage exec "${link_influxdb}" "curl -XPOST -u ${database_user}:${database_password} http://"${link_influxdb_ip4_addr%/*}":8086/query --data-urlencode 'q=CREATE DATABASE ${database}'"
        echo "Database ${database} created with username ${database_user} with password ${database_password}."
      fi
    fi
  else
    echo "Influxdb jail does not exist. Unifi-Poller requires Influxdb jail. Please install the Influxdb jail."
    exit 1
  fi

  # Download and install Unifi-Poller
  FILE_NAME=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .name")
  DOWNLOAD=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .browser_download_url")
  iocage exec "${1}" fetch -o /config "${DOWNLOAD}"

  # Install downloaded Unifi-Poller package, configure and enable 
  iocage exec "${1}" pkg install -qy /config/"${FILE_NAME}"
  cp "${includes_dir}"/up.conf /mnt/"${global_dataset_config}"/"${1}"
  cp "${includes_dir}"/rc/unifi_poller.rc /mnt/"${global_dataset_iocage}"/jails/"${1}"/root/usr/local/etc/rc.d/unifi_poller
  chmod +x /mnt/"${global_dataset_iocage}"/jails/"${1}"/root/usr/local/etc/rc.d/unifi_poller
  iocage exec "${1}" sed -i '' "s|influxdbuser|${database_user}|" /config/up.conf
  iocage exec "${1}" sed -i '' "s|influxdbpass|${database_password}|" /config/up.conf
  iocage exec "${1}" sed -i '' "s|unifidb|${database}|" /config/up.conf
  iocage exec "${1}" sed -i '' "s|unifiuser|${poller_user}|" /config/up.conf
  iocage exec "${1}" sed -i '' "s|unifipassword|${poller_password}|" /config/up.conf
  iocage exec "${1}" sed -i '' "s|dbip|http://${link_influxdb_ip4_addr%/*}:8086|" /config/up.conf


  iocage exec "${1}" sysrc unifi_poller_enable=YES
  iocage exec "${1}" service unifi_poller start

  echo "Please login to the Unifi Controller and add ${poller_user} as a read-only user."
fi

exitblueprint "$1" "Unifi Controller is now accessible at https://${jail_ip}:8443"

