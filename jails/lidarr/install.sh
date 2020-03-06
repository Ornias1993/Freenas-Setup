#!/usr/local/bin/bash
# This file contains the install script for lidarr

iocage exec lidarr mkdir -p /mnt/music
iocage exec lidarr mkdir -p /mnt/fetched

# Check if dataset for completed download and it parent dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}" ]; then
	echo "Downloads dataset does not exist... Creating... ${global_dataset_downloads}"
	zfs create ${global_dataset_downloads}
fi

if [ ! -d "/mnt/${global_dataset_downloads}/complete" ]; then
	echo "Completed Downloads dataset does not exist... Creating... ${global_dataset_downloads}/complete"
	zfs create ${global_dataset_downloads}/complete
fi

iocage fstab -a lidarr /mnt/${global_dataset_downloads}/complete /mnt/fetched nullfs rw 0 0

# Check if dataset for media library and the dataset for music exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_media}" ]; then
	echo "Media dataset does not exist... Creating... ${global_dataset_media}"
	zfs create ${global_dataset_media}
fi

if [ ! -d "/mnt/${global_dataset_media}/music" ]; then
	echo "Music dataset does not exist... Creating... ${global_dataset_media}/music"
	zfs create ${global_dataset_media}/music
fi

iocage fstab -a lidarr /mnt/${global_dataset_media}/music /mnt/music nullfs rw 0 0


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