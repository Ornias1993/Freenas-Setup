#!/usr/local/bin/bash
# This file contains the update script for radarr

iocage exec radarr service radarr stop
#TODO insert code to update radarr itself here
iocage exec radarr chown -R radarr:radarr /usr/local/share/Radarr /config
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/jails/radarr/includes/radarr.rc /mnt/"${global_dataset_iocage}"/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage exec radarr chmod u+x /usr/local/etc/rc.d/radarr
iocage exec radarr service radarr restart