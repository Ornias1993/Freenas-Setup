echo '{"pkgs":["python2","py27-sqlite3","py27-openssl","ca_root_nss","git","nano"]}' > /tmp/pkg.json
iocage create -n "tautulli" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.26/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec tautulli mkdir -p /config
iocage fstab -a tautulli /mnt/tank/apps/tautulli /config nullfs rw 0 0
iocage exec tautulli git clone https://github.com/Tautulli/Tautulli.git /usr/local/share/Tautulli
iocage exec tautulli "pw user add tautulli -c tautulli -u 109 -d /nonexistent -s /usr/bin/nologin"
iocage exec tautulli chown -R tautulli:tautulli /usr/local/share/Tautulli /config
iocage exec tautulli cp /usr/local/share/Tautulli/init-scripts/init.freenas /usr/local/etc/rc.d/tautulli
iocage exec tautulli chmod u+x /usr/local/etc/rc.d/tautulli
iocage exec tautulli sysrc "tautulli_enable=YES"
iocage exec tautulli sysrc "tautulli_flags=--datadir /config"
iocage exec tautulli service tautulli start