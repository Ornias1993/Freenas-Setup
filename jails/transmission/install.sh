echo '{"pkgs":["bash","unzip","unrar","transmission","ca_root_nss","nano"]}' > /tmp/pkg.json
iocage create -n "transmission" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.22/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec transmission mkdir -p /config
iocage exec transmission mkdir -p /mnt/downloads
iocage exec transmission mkdir -p /mnt/downloads/complete
iocage exec transmission mkdir -p /mnt/downloads/incomplete
iocage fstab -a transmission /mnt/tank/apps/transmission /config nullfs rw 0 0
iocage fstab -a transmission /mnt/tank/downloads /mnt/downloads nullfs rw 0 0
iocage fstab -a transmission /mnt/tank/downloads/complete /mnt/downloads/complete nullfs rw 0 0
iocage fstab -a transmission /mnt/tank/downloads/incomplete /mnt/downloads/incomplete nullfs rw 0 0
iocage exec transmission mkdir -p /config
iocage exec transmission chown -R transmission:transmission /config
iocage exec transmission sysrc "transmission_enable=YES"
iocage exec transmission sysrc "transmission_conf_dir=/config"
iocage exec transmission sysrc "transmission_download_dir=/mnt/downloads/complete"
iocage exec transmission service transmission start