#!/usr/local/bin/bash
# This file contains the install script for radarr

iocage exec radarr mkdir -p /mnt/movies
iocage exec radarr mkdir -p /mnt/fetched

# Check if dataset for completed download and it parent dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}" ]; then
	echo "Downloads dataset does not exist... Creating... ${global_dataset_downloads}"
	zfs create ${global_dataset_downloads}
fi

if [ ! -d "/mnt/${global_dataset_downloads}/complete" ]; then
	echo "Completed Downloads dataset does not exist... Creating... ${global_dataset_downloads}/complete"
	zfs create ${global_dataset_downloads}/complete
fi

iocage fstab -a radarr /mnt/${global_dataset_downloads}/complete /mnt/fetched nullfs rw 0 0

# Check if dataset for media library and the dataset for movies exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_media}" ]; then
	echo "Media dataset does not exist... Creating... ${global_dataset_media}"
	zfs create ${global_dataset_media}
fi

if [ ! -d "/mnt/${global_dataset_media}/movies" ]; then
	echo "Movies dataset does not exist... Creating... ${global_dataset_media}/movies"
	zfs create ${global_dataset_media}/movies
fi

iocage fstab -a radarr /mnt/${global_dataset_media}/movies /mnt/movies nullfs rw 0 0

iocage exec radarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec radarr "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.1480/Radarr.develop.0.2.0.1480.linux.tar.gz -o /usr/local/share"
iocage exec radarr "tar -xzvf /usr/local/share/Radarr.develop.0.2.0.1480.linux.tar.gz -C /usr/local/share"
iocage exec radarr rm /usr/local/share/Radarr.develop.0.2.0.1480.linux.tar.gz
iocage exec radarr "pw user add radarr -c radarr -u 352 -d /nonexistent -s /usr/bin/nologin"
iocage exec radarr chown -R radarr:radarr /usr/local/share/Radarr /config
iocage exec radarr mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/radarr/includes/radarr.rc /mnt/${global_dataset_iocage}/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage exec radarr chmod u+x /usr/local/etc/rc.d/radarr
iocage exec radarr sysrc "radarr_enable=YES"
iocage exec radarr service radarr restart