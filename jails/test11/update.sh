#!/usr/local/bin/bash
# This file contains the update script for sonarr

iocage exec test11 service sonarr stop
#TODO insert code to update sonarr itself here
iocage exec test11 chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
cp ${SCRIPT_DIR}/jails/test11/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/test11/root/usr/local/etc/rc.d/sonarr
iocage exec test11 chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec test11 service sonarr restart