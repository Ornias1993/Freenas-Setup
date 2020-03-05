iocage exec lidarr service lidarr stop
iocage update lidarr
iocage exec lidarr "pkg update && pkg upgrade -y"
iocage exec lidarr chown -R lidarr:lidarr /usr/local/share/Lidarr /config
cp ../includes/lidarr-conf/lidarr.rc /mnt/tank/iocage/jails/lidarr/root/usr/local/etc/rc.d/lidarr
iocage exec lidarr chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec lidarr service lidarr restart