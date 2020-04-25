#!/usr/local/bin/bash
# This file contains the update script for jackett

iocage exec jackett service jackett stop
#TODO insert code to update jacket itself here
iocage exec jackett chown -R jackett:jackett /usr/local/share/Jackett /config
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/jails/test10/includes/jackett.rc /mnt/"${global_dataset_iocage}"/jails/test10/root/usr/local/etc/rc.d/jackett
iocage exec jackett chmod u+x /usr/local/etc/rc.d/jackett
iocage exec jackett service jackett restart
