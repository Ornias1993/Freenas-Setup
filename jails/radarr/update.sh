iocage exec radarr service radarr stop
iocage update radarr
iocage exec radarr "pkg update && pkg upgrade -y"
iocage exec radarr chown -R radarr:radarr /usr/local/share/Radarr /config
cp ../includes/radarr-conf/radarr.rc /mnt/tank/iocage/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage exec radarr chmod u+x /usr/local/etc/rc.d/radarr
iocage exec radarr service radarr restart