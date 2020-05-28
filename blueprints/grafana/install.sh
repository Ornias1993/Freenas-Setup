#!/usr/local/bin/bash
#This file contains the install script for Grafana

#init jail
initblueprint "$1"

# Initialise defaults
user="${user:-$1}"
password="jail_${1}_password"
password="${!password}"

DB_IP="jail_${link_influxdb}_ip4_addr"
DB_IP="${!DB_IP%/*}"

iocage exec "${1}" mkdir -p /config/db
iocage exec "${1}" mkdir -p /config/logs
iocage exec "${1}" mkdir -p /config/plugins
iocage exec "${1}" mkdir -p /config/provisioning/datasources

if [ ! "${user}" == "grafana" ]; then
  iocage exec "$1" "pw user add ${user} -n ${user} -d /nonexistent -s /usr/bin/nologin"
fi

cp "${includes_dir}"/grafana.conf /mnt/"${global_dataset_config}"/"${1}"

iocage exec "${1}" sed -i '' "s|jail_admin|${user}|" /config/grafana.conf
iocage exec "${1}" sed -i '' "s|jail_password|${password}|" /config/grafana.conf

if [ -n "${link_influxdb}" ]; then
  datasource_name="jail_${1}_link_influxdb_name"
  datasource_db="jail_${1}_link_influxdb_database"
  datasource_user="jail_${1}_link_influxdb_user"
  datasource_password="jail_${1}_link_influxdb_password"
  cp "${includes_dir}"/influxdb.yaml /mnt/"${global_dataset_config}"/"${1}"/provisioning/datasources
  iocage exec "${1}" sed -i '' "s|datasource_name|${!datasource_name}|" /config/provisioning/datasources/influxdb.yaml
  iocage exec "${1}" sed -i '' "s|influxdb_ip|${DB_IP}|" /config/provisioning/datasources/influxdb.yaml
  iocage exec "${1}" sed -i '' "s|datasource_db|${!datasource_db}|" /config/provisioning/datasources/influxdb.yaml
  iocage exec "${1}" sed -i '' "s|datasource_user|${!datasource_user}|" /config/provisioning/datasources/influxdb.yaml
  iocage exec "${1}" sed -i '' "s|datasource_pass|${!datasource_password}|" /config/provisioning/datasources/influxdb.yaml
fi

iocage exec "${1}" chown -R "${user}":grafana /config

iocage exec "${1}" sysrc grafana_conf="/config/grafana.conf"
iocage exec "${1}" sysrc grafana_user="${user}"
iocage exec "${1}" sysrc grafana_enable="YES" 
iocage exec "${1}" service grafana start

echo "Installation complete!"
echo "${1} is accessible at https://${ip4_addr%/*}:3000."
