#!/usr/local/bin/bash
# This script installs the current release of Mariadb and PhpMyAdmin into a created jail

#####
# 
# Init and Mounts
#
#####

# Initialise defaults
JAIL_NAME="testmdb"
JAIL_IP="$(sed 's|\(.*\)/.*|\1|' <<<"${testmdb_ip4_addr}" )"
INCLUDES_PATH="${SCRIPT_DIR}/jails/testmdb/includes"
CERT_EMAIL=${testmdb_cert_email}
DB_ROOT_PASSWORD=${testmdb_db_root_password}
DB_NAME="MariaDB"
DB_HOST="localhost:/tmp/mysql.sock"
DL_FLAGS="http.git"


# Check that necessary variables were set by nextcloud-config
if [ -z "${testmdb_ip4_addr}" ]; then
  echo 'Configuration error: The mariadb jail does NOT accept DHCP'
  echo 'Please reinstall using a fixed IP adress'
  exit 1
fi

# Make sure DB_PATH is empty -- if not, MariaDB/PostgreSQL will choke

if [ "$(ls -A "/mnt/${global_dataset_config}/${JAIL_NAME}/db")" ]; then
	echo "Reinstall of mariadb detected... Continuing"
	REINSTALL="true"
fi

createmount ${JAIL_NAME} ${global_dataset_config}/${JAIL_NAME}/db /var/db/mysql
iocage exec "${JAIL_NAME}" chown -R 88:88 /var/db/mysql

# Install includes fstab
iocage exec "${JAIL_NAME}" mkdir -p /mnt/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

iocage exec "${JAIL_NAME}" mkdir -p /usr/local/www/phpmyadmin
iocage exec "${JAIL_NAME}" chown -R www:www /usr/local/www/phpmyadmin

#####
# 
# Install mariadb, Caddy and Php my admin
#
#####

fetch -o /tmp https://getcaddy.com
if ! iocage exec "${JAIL_NAME}" bash -s personal "${DL_FLAGS}" < /tmp/getcaddy.com
then
	echo "Failed to download/install Caddy"
	exit 1
fi

iocage exec "${JAIL_NAME}" sysrc mysql_enable="YES"

# Copy and edit pre-written config files
echo "Copying Caddyfile for no SSL"
iocage exec "${JAIL_NAME}" cp -f /mnt/includes/caddy /usr/local/etc/rc.d/
iocage exec "${JAIL_NAME}" cp -f /mnt/includes/Caddyfile /usr/local/www/Caddyfile
iocage exec "${JAIL_NAME}" sed -i '' "s/yourhostnamehere/${testmdb_host_name}/" /usr/local/www/Caddyfile
iocage exec "${JAIL_NAME}" sed -i '' "s/JAIL-IP/${JAIL_IP}/" /usr/local/www/Caddyfile

iocage exec "${JAIL_NAME}" sysrc caddy_enable="YES"
iocage exec "${JAIL_NAME}" sysrc php_fpm_enable="YES"
iocage exec "${JAIL_NAME}" sysrc caddy_cert_email="${CERT_EMAIL}"
iocage exec "${JAIL_NAME}" sysrc caddy_env="${DNS_ENV}"

iocage restart "${JAIL_NAME}"
sleep 10

if [ "${REINSTALL}" == "true" ]; then
	echo "Reinstall detected, skipping generaion of new config and database"
else
	
	# Secure database, set root password, create Nextcloud DB, user, and password
	iocage exec "${JAIL_NAME}" cp -f /mnt/includes/my-system.cnf /var/db/mysql/my.cnf
	iocage exec "${JAIL_NAME}" mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
	iocage exec "${JAIL_NAME}" mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	iocage exec "${JAIL_NAME}" mysql -u root -e "DROP DATABASE IF EXISTS test;"
	iocage exec "${JAIL_NAME}" mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
	iocage exec "${JAIL_NAME}" mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('${DB_ROOT_PASSWORD}') WHERE User='root';"
	iocage exec "${JAIL_NAME}" mysqladmin reload
fi
	iocage exec "${JAIL_NAME}" cp -f /mnt/includes/my.cnf /root/.my.cnf
	iocage exec "${JAIL_NAME}" sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf

	# Save passwords for later reference
	iocage exec "${JAIL_NAME}" echo "${DB_NAME} root password is ${DB_ROOT_PASSWORD}" > /root/${JAIL_NAME}_db_password.txt
	

# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

# Done!
echo "Installation complete!"
echo "Using your web browser, go to http://${testmdb_host_name} to log in"

if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please use your old database and account credentials"
else

	echo "Default user is admin, password is ${ADMIN_PASSWORD}"
	echo ""

	echo "Database Information"
	echo "--------------------"
	echo "Database user = ${DB_USER}"
	echo "Database password = ${DB_PASSWORD}"
	if [ "${DATABASE}" = "mariadb" ] || [ "${DATABASE}" = "pgsql" ]; then
		echo "The ${DB_NAME} root password is ${DB_ROOT_PASSWORD}"
	fi
	echo ""
	echo "All passwords are saved in /root/${JAIL_NAME}_db_password.txt"
fi

