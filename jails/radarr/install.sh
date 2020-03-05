echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl","nano"]}' > /tmp/pkg.json
iocage create -n "radarr" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.24/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec radarr mkdir -p /config
iocage exec radarr mkdir -p /mnt/movies
iocage exec radarr mkdir -p /mnt/fetched
iocage fstab -a radarr /mnt/tank/apps/radarr /config nullfs rw 0 0
iocage fstab -a radarr /mnt/tank/downloads/complete /mnt/fetched nullfs rw 0 0
iocage fstab -a radarr /mnt/tank/library/Movies /mnt/movies nullfs rw 0 0
iocage exec radarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec radarr "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.1480/Radarr.develop.0.2.0.1480.linux.tar.gz -o /usr/local/share"
iocage exec radarr "tar -xzvf /usr/local/share/Radarr.develop.0.2.0.1480.linux.tar.gz -C /usr/local/share"
iocage exec radarr rm /usr/local/share/Radarr.develop.0.2.0.1480.linux.tar.gz
iocage exec radarr "pw user add radarr -c radarr -u 352 -d /nonexistent -s /usr/bin/nologin"
iocage exec radarr chown -R radarr:radarr /usr/local/share/Radarr /config
iocage exec radarr mkdir /usr/local/etc/rc.d
cp ../includes/radarr-conf/radarr.rc /mnt/tank/iocage/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage exec radarr chmod u+x /usr/local/etc/rc.d/radarr
iocage exec radarr sysrc "radarr_enable=YES"
iocage exec radarr service radarr start