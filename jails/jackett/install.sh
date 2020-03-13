#!/usr/local/bin/bash
# This file contains the install script for jackett

iocage exec jackett "fetch https://github.com/Jackett/Jackett/releases/download/v0.11.502/Jackett.Binaries.Mono.tar.gz -o /usr/local/share"
iocage exec jackett "tar -xzvf /usr/local/share/Jackett.Binaries.Mono.tar.gz -C /usr/local/share"
iocage exec jackett rm /usr/local/share/Jackett.Binaries.Mono.tar.gz
iocage exec jackett "pw user add jackett -c jackett -u 818 -d /nonexistent -s /usr/bin/nologin"
iocage exec jackett chown -R jackett:jackett /usr/local/share/Jackett /config
iocage exec jackett mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/jackett/includes/jackett.rc /mnt/${global_dataset_iocage}/jails/jackett/root/usr/local/etc/rc.d/jackett
iocage exec jackett chmod u+x /usr/local/etc/rc.d/jackett
iocage exec jackett sysrc "jackett_enable=YES"
iocage exec jackett service jackett restart
