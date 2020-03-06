#!/usr/local/bin/bash
# This file contains the install script for transmission

iocage exec transmission mkdir -p /mnt/downloads
iocage exec transmission mkdir -p /mnt/downloads/complete
iocage exec transmission mkdir -p /mnt/downloads/incomplete

# Check if dataset Downloads dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}" ]; then
	echo "Downloads dataset does not exist... Creating... ${global_dataset_downloads}"
	zfs create ${global_dataset_downloads}
fi

iocage fstab -a transmission /mnt/${global_dataset_downloads} /mnt/downloads nullfs rw 0 0

# Check if dataset Complete Downloads dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}/complete" ]; then
	echo "Completed Downloads dataset does not exist... Creating... ${global_dataset_downloads}/complete"
	zfs create ${global_dataset_downloads}/complete
fi

iocage fstab -a transmission /mnt/${global_dataset_downloads}/complete /mnt/downloads/complete nullfs rw 0 0

# Check if dataset InComplete Downloads dataset exist, create if they do not.
if [ ! -d "/mnt/${global_dataset_downloads}/incomplete" ]; then
	echo "Completed Downloads dataset does not exist... Creating... ${global_dataset_downloads}/incomplete"
	zfs create ${global_dataset_downloads}/incomplete
fi

iocage fstab -a transmission /mnt/${global_dataset_downloads}/incomplete /mnt/downloads/incomplete nullfs rw 0 0


iocage exec transmission mkdir -p /config
iocage exec transmission chown -R transmission:transmission /config
iocage exec transmission sysrc "transmission_enable=YES"
iocage exec transmission sysrc "transmission_conf_dir=/config"
iocage exec transmission sysrc "transmission_download_dir=/mnt/downloads/complete"
iocage exec transmission service transmission restart