#!/usr/local/bin/bash
#This file contains the install script for Grafana

JAIL_IP="jail_${1}_ip4_addr"
JAIL_IP="${!JAIL_IP%/*}"
USER="jail_${1}_user"
USER="${!USER:-$1}"
PASS="jail_${1}_password"
INCLUDES_PATH="${SCRIPT_DIR}/blueprints/grafana/includes"

if [ -z "${!PASS}" ]; then
  echo "Password cannot be empty."
  exit 1
fi

iocage exec "${1}" mkdir -p /config/db
iocage exec "${1}" mkdir -p /config/logs
iocage exec "${1}" mkdir -p /config/plugins
iocage exec "${1}" mkdir -p /config/provisioning

cp "${INCLUDES_PATH}"/grafana.conf /mnt/"${global_dataset_config}"/"${1}"

if [ ! "${USER}" == "grafana" ]; then
  iocage exec "$1" "pw user add ${USER} -n ${USER} -d /nonexistent -s /usr/bin/nologin"
fi

iocage exec "${1}" chown -R "${USER}":grafana /config

iocage exec "${1}" sed -i '' "s|jail_admin|${USER}|" /config/grafana.conf
iocage exec "${1}" sed -i '' "s|jail_password|${!PASS}|" /config/grafana.conf

iocage exec "${1}" sysrc grafana_conf="/config/grafana.conf"
iocage exec "${1}" sysrc grafana_user="${USER}"
iocage exec "${1}" sysrc grafana_enable="YES" 
iocage exec "${1}" service grafana start