#!/usr/local/bin/bash
# This file contains the install script for test11

createmount test11 ${global_dataset_downloads}
createmount test11 ${global_dataset_downloads}/complete /mnt/fetched
createmount test11 ${global_dataset_media}
createmount test11 ${global_dataset_media}/shows /mnt/shows


iocage exec test11 ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec test11 "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec test11 "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec test11 rm /usr/local/share/NzbDrone.master.tar.gz
iocage exec test11 "pw user add sonarr -c sonarr -u 351 -d /nonexistent -s /usr/bin/nologin"
iocage exec test11 chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
iocage exec test11 mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/test11/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/test11/root/usr/local/etc/rc.d/sonarr
iocage exec test11 chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec test11 sysrc "sonarr_enable=YES"
iocage exec test11 service sonarr restart