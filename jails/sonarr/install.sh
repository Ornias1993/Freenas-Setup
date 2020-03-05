echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl","nano"]}' > /tmp/pkg.json
iocage create -n "sonarr" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.23/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec sonarr mkdir -p /config
iocage exec sonarr mkdir -p /mnt/series
iocage exec sonarr mkdir -p /mnt/fetched
iocage fstab -a sonarr /mnt/tank/apps/sonarr /config nullfs rw 0 0
iocage fstab -a sonarr /mnt/tank/downloads/complete /mnt/fetched nullfs rw 0 0
iocage fstab -a sonarr /mnt/tank/library/Series /mnt/series nullfs rw 0 0
iocage exec sonarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec sonarr "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec sonarr "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec sonarr rm /usr/local/share/NzbDrone.master.tar.gz
iocage exec sonarr "pw user add sonarr -c sonarr -u 351 -d /nonexistent -s /usr/bin/nologin"
iocage exec sonarr chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
iocage exec sonarr mkdir /usr/local/etc/rc.d
cp ../includes/sonarr-conf/sonarr.rc /mnt/tank/iocage/jails/sonarr/root/usr/local/etc/rc.d/sonarr
iocage exec sonarr chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec sonarr sysrc "sonarr_enable=YES"
iocage exec sonarr service sonarr start