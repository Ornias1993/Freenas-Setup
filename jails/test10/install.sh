#!/usr/local/bin/bash
# This file contains the install script for test10

iocage exec test10 mkdir -p /mnt/shows
iocage exec test10 mkdir -p /mnt/fetched

# Check if dataset for completed download and it parent dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}" ]; then
echo "Config dataset does not exist... Creating... ${global_dataset_downloads}"
zfs create ${global_dataset_downloads}
fi

if [ ! -d "/mnt/${global_dataset_downloads}/complete" ]; then
echo "Config dataset does not exist... Creating... ${global_dataset_downloads}/complete"
zfs create ${global_dataset_downloads}/complete
fi

iocage fstab -a test10 /mnt/${global_dataset_downloads}/complete /mnt/fetched nullfs rw 0 0

# Check if dataset for media library and the dataset for tv shows exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_media}" ]; then
	echo "Config dataset does not exist... Creating... ${global_dataset_media}"
zfs create ${global_dataset_media}
fi

if [ ! -d "/mnt/${global_dataset_media}/shows" ]; then
echo "Config dataset does not exist... Creating... ${global_dataset_media}/shows"
zfs create ${global_dataset_media}/shows
fi

iocage fstab -a test10 /mnt/${global_dataset_media}/shows /mnt/shows nullfs rw 0 0


iocage exec test10 ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec test10 "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec test10 "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec test10 rm /usr/local/share/NzbDrone.master.tar.gz
iocage exec test10 "pw user add sonarr -c sonarr -u 351 -d /nonexistent -s /usr/bin/nologin"
iocage exec test10 chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
iocage exec test10 mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/test10/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/test10/root/usr/local/etc/rc.d/sonarr
iocage exec test10 chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec test10 sysrc "sonarr_enable=YES"
iocage exec test10 service sonarr restart