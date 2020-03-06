#!/usr/local/bin/bash
# This file contains the update script for sonarr

iocage exec sonarr service sonarr stop
#TODO insert code to update sonarr itself here
iocage exec sonarr chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
cp ${SCRIPT_DIR}/jails/sonarr/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/sonarr/root/usr/local/etc/rc.d/sonarr
iocage exec sonarr chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec sonarr service sonarr restart