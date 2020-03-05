iocage exec jackett service jackett stop
iocage update jackett
iocage exec jackett "pkg update && pkg upgrade -y"
iocage exec jackett chown -R jackett:jackett /usr/local/share/Jackett /config
cp ../includes/jackett-conf/jackett.rc /mnt/tank/iocage/jails/jackett/root/usr/local/etc/rc.d/jackett
iocage exec jackett chmod u+x /usr/local/etc/rc.d/jackett
iocage exec jackett service jackett restart