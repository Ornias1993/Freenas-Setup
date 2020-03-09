#!/usr/local/bin/bash
# This file contains the update script for bitwarden
# Due to it being build from scratch or downloaded directly to execution dir, 
# Update for Bitwarden is pretty similair to installation

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

iocage exec ${JAIL_NAME} service bitwarden stop

# install latest rust version, pkg version is outdated and can't build bitwarden_rs
iocage exec ${JAIL_NAME} "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

# Install Bitwarden_rs
iocage exec ${JAIL_NAME} "git -C /usr/local/share/bitwarden/src fetch"
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

iocage exec ${JAIL_NAME} chown -R bitwarden:bitwarden /usr/local/share/bitwarden /config
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
iocage exec ${JAIL_NAME} service bitwarden restart
echo "Jail ${JAIL_NAME} finished Bitwarden update."
echo "Admin Token is ${ADMIN_TOKEN}"
