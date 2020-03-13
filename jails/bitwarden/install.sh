#!/usr/local/bin/bash
# This file contains the install script for bitwarden

# Initialise defaults
JAIL_NAME="bitwarden"
DB_DATABASE=${JAIL_NAME}
DB_USER=${JAIL_NAME}
INSTALL_TYPE=${bitwarden_type}
DB_HOST="$(sed 's|\(.*\)/.*|\1|' <<<"${mariadb_ip4_addr}"):3306"
DB_PASSWORD="${bitwarden_db_password}"
DB_STRING="mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_DATABASE}"
ADMIN_TOKEN=${bitwarden_admin_token}

if [ -z "${ADMIN_TOKEN}" ]; then
ADMIN_TOKEN=$(openssl rand -base64 16)
fi

# install latest rust version, pkg version is outdated and can't build bitwarden_rs
iocage exec ${JAIL_NAME} "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

# Install Bitwarden_rs
iocage exec ${JAIL_NAME} mkdir -p /usr/local/share/bitwarden/src
iocage exec ${JAIL_NAME} git clone https://github.com/dani-garcia/bitwarden_rs/ /usr/local/share/bitwarden/src
TAG=$(iocage exec ${JAIL_NAME} "git -C /usr/local/share/bitwarden/src tag --sort=v:refname | tail -n1")
iocage exec ${JAIL_NAME} "git -C /usr/local/share/bitwarden/src checkout ${TAG}"
#TODO replace with: cargo build --features mysql --release
if [ "${INSTALL_TYPE}" == "mariadb" ]; then
	iocage exec ${JAIL_NAME} "cd /usr/local/share/bitwarden/src && $HOME/.cargo/bin/cargo build --features mysql --release"
	iocage exec ${JAIL_NAME} "cd /usr/local/share/bitwarden/src && $HOME/.cargo/bin/cargo install diesel_cli --no-default-features --features mysql"
else
	iocage exec ${JAIL_NAME} "cd /usr/local/share/bitwarden/src && $HOME/.cargo/bin/cargo build --features sqlite --release"
	iocage exec ${JAIL_NAME} "cd /usr/local/share/bitwarden/src && $HOME/.cargo/bin/cargo install diesel_cli --no-default-features --features sqlite-bundled"
fi


iocage exec ${JAIL_NAME} cp -r /usr/local/share/bitwarden/src/target/release /usr/local/share/bitwarden/bin

# Download and install webvault
WEB_RELEASE_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/dani-garcia/bw_web_builds/releases/latest)
WEB_TAG="${WEB_RELEASE_URL##*/}"
iocage exec ${JAIL_NAME} "fetch http://github.com/dani-garcia/bw_web_builds/releases/download/$WEB_TAG/bw_web_$WEB_TAG.tar.gz -o /usr/local/share/bitwarden"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/bitwarden/bw_web_$WEB_TAG.tar.gz -C /usr/local/share/bitwarden/"
iocage exec ${JAIL_NAME} rm /usr/local/share/bitwarden/bw_web_$WEB_TAG.tar.gz

if [ -f "/mnt/${global_dataset_config}/${JAIL_NAME}/ssl/bitwarden-ssl.crt" ]; then
    echo "certificate exist... Skipping cert generation"
else
	"No ssl certificate present, generating self signed certificate"
	if [ ! -d "/mnt/${global_dataset_config}/${JAIL_NAME}/ssl" ]; then
		echo "cert folder not existing... creating..."
		iocage exec ${JAIL_NAME} mkdir /config/ssl
	fi
	openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" -keyout /mnt/${global_dataset_config}/${JAIL_NAME}/ssl/bitwarden-ssl.key -out /mnt/${global_dataset_config}/${JAIL_NAME}/ssl/bitwarden-ssl.crt
fi

if [ -f "/mnt/${global_dataset_config}/${JAIL_NAME}/bitwarden.log" ]; then
	echo "Reinstall of Bitwarden detected... using existing config and database"
elif [ "${INSTALL_TYPE}" == "mariadb" ]; then
	echo "No config detected, doing clean install, utilizing the Mariadb database ${DB_HOST}"
	iocage exec "mariadb" mysql -u root -e "CREATE DATABASE ${DB_DATABASE};"
	iocage exec "mariadb" mysql -u root -e "GRANT ALL ON ${DB_DATABASE}.* TO ${DB_USER}@${JAIL_IP} IDENTIFIED BY '${DB_PASSWORD}';"
	iocage exec "mariadb" mysqladmin reload
else
	echo "No config detected, doing clean install."
fi

iocage exec ${JAIL_NAME} "pw user add bitwarden -c bitwarden -u 725 -d /nonexistent -s /usr/bin/nologin"
iocage exec ${JAIL_NAME} chown -R bitwarden:bitwarden /usr/local/share/bitwarden /config
iocage exec ${JAIL_NAME} mkdir /usr/local/etc/rc.d /usr/local/etc/rc.conf.d
cp ${SCRIPT_DIR}/jails/${JAIL_NAME}/includes/bitwarden.rc /mnt/${global_dataset_iocage}/jails/${JAIL_NAME}/root/usr/local/etc/rc.d/bitwarden
cp ${SCRIPT_DIR}/jails/${JAIL_NAME}/includes/bitwarden.rc.conf /mnt/${global_dataset_iocage}/jails/${JAIL_NAME}/root/usr/local/etc/rc.conf.d/bitwarden
echo 'export DATABASE_URL="'${DB_STRING}'"' >> /mnt/${global_dataset_iocage}/jails/${JAIL_NAME}/root/usr/local/etc/rc.conf.d/bitwarden
echo 'export ADMIN_TOKEN="'${ADMIN_TOKEN}'"' >> /mnt/${global_dataset_iocage}/jails/${JAIL_NAME}/root/usr/local/etc/rc.conf.d/bitwarden

if [ "${ADMIN_TOKEN}" == "NONE" ]; then
	echo "Admin_token set to NONE, disabling admin portal"
else
	echo "Admin_token set and admin portal enabled"
	iocage exec "${JAIL_NAME}" echo "${DB_NAME} Admin Token is ${ADMIN_TOKEN}" > /root/${JAIL_NAME}_admin_token.txt
fi

iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/bitwarden
iocage exec ${JAIL_NAME} sysrc "bitwarden_enable=YES"
iocage exec ${JAIL_NAME} service bitwarden restart
echo "Jail ${JAIL_NAME} finished Bitwarden install."
echo "Admin Token is ${ADMIN_TOKEN}"
