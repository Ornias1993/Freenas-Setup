echo '{"pkgs":["mono","curl","ca_root_nss","nano"]}' > /tmp/pkg.json
iocage create -n "jackett" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.30/24" defaultrouter="192.168.21.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec jackett mkdir -p /config
iocage fstab -a jackett /mnt/tank/apps/jackett /config nullfs rw 0 0
iocage exec jackett ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec jackett "fetch https://github.com/Jackett/Jackett/releases/download/v0.11.502/Jackett.Binaries.Mono.tar.gz -o /usr/local/share"
iocage exec jackett "tar -xzvf /usr/local/share/Jackett.Binaries.Mono.tar.gz -C /usr/local/share"
iocage exec jackett rm /usr/local/share/Jackett.Binaries.Mono.tar.gz
iocage exec jackett "pw user add jackett -c jackett -u 818 -d /nonexistent -s /usr/bin/nologin"
iocage exec jackett chown -R jackett:jackett /usr/local/share/Jackett /config
iocage exec jackett mkdir /usr/local/etc/rc.d
cp ../includes/jackett-conf/jackett.rc /mnt/tank/iocage/jails/jackett/root/usr/local/etc/rc.d/jackett
iocage exec jackett chmod u+x /usr/local/etc/rc.d/jackett
iocage exec jackett sysrc "jackett_enable=YES"
iocage exec jackett service jackett restart