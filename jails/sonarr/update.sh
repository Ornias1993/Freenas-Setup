iocage exec sonarr service sonarr stop
iocage update sonarr
iocage exec sonarr "pkg update && pkg upgrade -y"
iocage exec sonarr chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
cp ../includes/sonarr-conf/sonarr.rc /mnt/tank/iocage/jails/sonarr/root/usr/local/etc/rc.d/sonarr
iocage exec sonarr chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec sonarr service sonarr restart