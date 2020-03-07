#!/usr/local/bin/bash
# This file contains the install script for lidarr

# Check if dataset for completed download and it parent dataset exist, create if they do not.
createmount lidarr ${global_dataset_downloads}
createmount lidarr ${global_dataset_downloads}/complete /mnt/fetched

# Check if dataset for media library and the dataset for movies exist, create if they do not.
createmount lidarr ${global_dataset_media}
createmount lidarr ${global_dataset_media}/music /mnt/music


iocage exec lidarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec lidarr "fetch https://github.com/lidarr/Lidarr/releases/download/v0.2.0.371/Lidarr.develop.0.2.0.371.linux.tar.gz -o /usr/local/share"
iocage exec lidarr "tar -xzvf /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz -C /usr/local/share"
iocage exec lidarr "rm /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz"
iocage exec lidarr "pw user add lidarr -c lidarr -u 353 -d /nonexistent -s /usr/bin/nologin"
iocage exec lidarr chown -R lidarr:lidarr /usr/local/share/Lidarr /config
iocage exec lidarr mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/lidarr/includes/lidarr.rc /mnt/${global_dataset_iocage}/jails/lidarr/root/usr/local/etc/rc.d/lidarr
iocage exec lidarr chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec lidarr sysrc "lidarr_enable=YES"
iocage exec lidarr service lidarr start