#!/usr/local/bin/bash
# This file contains the update script for lidarr

iocage exec lidarr service lidarr stop
#TODO insert code to update lidarr itself here
iocage exec lidarr chown -R lidarr:lidarr /usr/local/share/lidarr /config
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/jails/lidarr/includes/lidarr.rc /mnt/"${global_dataset_iocage}"/jails/lidarr/root/usr/local/etc/rc.d/lidarr
iocage exec lidarr chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec lidarr service lidarr restart