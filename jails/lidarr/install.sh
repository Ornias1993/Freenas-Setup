echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl","chromaprint","nano"]}' > /tmp/pkg.json
iocage create -n "lidarr" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.25/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec lidarr mkdir -p /config
iocage exec lidarr mkdir -p /mnt/music
iocage exec lidarr mkdir -p /mnt/fetched
iocage fstab -a lidarr /mnt/tank/apps/lidarr /config nullfs rw 0 0
iocage fstab -a lidarr /mnt/tank/downloads/complete /mnt/fetched nullfs rw 0 0
iocage fstab -a lidarr /mnt/tank/library/Music /mnt/music nullfs rw 0 0
iocage exec lidarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec lidarr "fetch https://github.com/lidarr/Lidarr/releases/download/v0.2.0.371/Lidarr.develop.0.2.0.371.linux.tar.gz -o /usr/local/share"
iocage exec lidarr "tar -xzvf /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz -C /usr/local/share"
iocage exec lidarr "rm /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz"
iocage exec lidarr "pw user add lidarr -c lidarr -u 353 -d /nonexistent -s /usr/bin/nologin"
iocage exec lidarr chown -R lidarr:lidarr /usr/local/share/Lidarr /config
iocage exec lidarr mkdir /usr/local/etc/rc.d
cp ../includes/lidarr-conf/lidarr.rc /mnt/tank/iocage/jails/lidarr/root/usr/local/etc/rc.d/lidarr
iocage exec lidarr chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec lidarr sysrc "lidarr_enable=YES"
iocage exec lidarr service lidarr start