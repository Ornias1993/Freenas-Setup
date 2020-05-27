#!/usr/local/bin/bash
#This file contains the install script for Grafana

#init jail
initblueprint "$1"

# Initialise defaults
user="${user:-$1}"

iocage exec "${1}" mkdir -p /config/db
iocage exec "${1}" mkdir -p /config/logs
iocage exec "${1}" mkdir -p /config/plugins
iocage exec "${1}" mkdir -p /config/provisioning

cp "${includes_dir}"/grafana.conf /mnt/"${global_dataset_config}"/"${1}"

if [ ! "${user}" == "grafana" ]; then
  iocage exec "$1" "pw user add ${user} -n ${user} -d /nonexistent -s /usr/bin/nologin"
fi

iocage exec "${1}" chown -R "${user}":grafana /config

iocage exec "${1}" sed -i '' "s|jail_admin|${user}|" /config/grafana.conf
iocage exec "${1}" sed -i '' "s|jail_password|${!password}|" /config/grafana.conf

iocage exec "${1}" sysrc grafana_conf="/config/grafana.conf"
iocage exec "${1}" sysrc grafana_user="${user}"
iocage exec "${1}" sysrc grafana_enable="YES" 
iocage exec "${1}" service grafana start