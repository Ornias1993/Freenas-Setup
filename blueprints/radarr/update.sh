#!/usr/local/bin/bash
# This file contains the update script for radarr

#init jail
initjail "$1"

# Initialise defaults

iocage exec "$1" service radarr stop
#TODO insert code to update radarr itself here
iocage exec "$1" chown -R radarr:radarr /usr/local/share/Radarr /config
cp "${SCRIPT_DIR}"/blueprints/radarr/includes/radarr.rc /mnt/"${global_dataset_iocage}"/jails/"$1"/root/usr/local/etc/rc.d/radarr
iocage exec "$1" chmod u+x /usr/local/etc/rc.d/radarr
iocage exec "$1" service radarr restart