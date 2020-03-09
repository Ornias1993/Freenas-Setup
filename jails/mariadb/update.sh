#!/usr/local/bin/bash
# This file contains the update script for mariadb

JAIL_NAME="mariadb"
JAIL_IP="$(sed 's|\(.*\)/.*|\1|' <<<"${mariadb_ip4_addr}" )"
INCLUDES_PATH="${SCRIPT_DIR}/jails/mariadb/includes"

# Install includes fstab
iocage exec "${JAIL_NAME}" mkdir -p /mnt/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0


iocage exec ${JAIL_NAME} service caddy stop
iocage exec ${JAIL_NAME} service php-fpm stop

fetch -o /tmp https://getcaddy.com
if ! iocage exec "${JAIL_NAME}" bash -s personal "${DL_FLAGS}" < /tmp/getcaddy.com
then
	echo "Failed to download/install Caddy"
	exit 1
fi

# Copy and edit pre-written config files
echo "Copying Caddyfile for no SSL"
iocage exec "${JAIL_NAME}" cp -f /mnt/includes/caddy /usr/local/etc/rc.d/
iocage exec "${JAIL_NAME}" cp -f /mnt/includes/Caddyfile /usr/local/www/Caddyfile
iocage exec "${JAIL_NAME}" sed -i '' "s/yourhostnamehere/${mariadb_host_name}/" /usr/local/www/Caddyfile
iocage exec "${JAIL_NAME}" sed -i '' "s/JAIL-IP/${JAIL_IP}/" /usr/local/www/Caddyfile

# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

iocage exec ${JAIL_NAME} service caddy start
iocage exec ${JAIL_NAME} service php-fpm start