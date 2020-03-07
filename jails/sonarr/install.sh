#!/usr/local/bin/bash
# This file contains the install script for sonarr

# Check if dataset for completed download and it parent dataset exist, create if they do not.
createmount sonarr ${global_dataset_downloads}
createmount sonarr ${global_dataset_downloads}/complete /mnt/fetched

# Check if dataset for media library and the dataset for tv shows exist, create if they do not.
createmount sonarr ${global_dataset_media}
createmount sonarr ${global_dataset_media}/shows /mnt/shows

iocage exec sonarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec sonarr "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec sonarr "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec sonarr rm /usr/local/share/NzbDrone.master.tar.gz
iocage exec sonarr "pw user add sonarr -c sonarr -u 351 -d /nonexistent -s /usr/bin/nologin"
iocage exec sonarr chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
iocage exec sonarr mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/sonarr/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/sonarr/root/usr/local/etc/rc.d/sonarr
iocage exec sonarr chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec sonarr sysrc "sonarr_enable=YES"
iocage exec sonarr service sonarr restart