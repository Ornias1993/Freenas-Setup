iocage exec test10 ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec test10 "fetch https://github.com/Jackett/Jackett/releases/download/v0.11.502/Jackett.Binaries.Mono.tar.gz -o /usr/local/share"
iocage exec test10 "tar -xzvf /usr/local/share/Jackett.Binaries.Mono.tar.gz -C /usr/local/share"
iocage exec test10 rm /usr/local/share/Jackett.Binaries.Mono.tar.gz
iocage exec test10 "pw user add jackett -c jackett -u 818 -d /nonexistent -s /usr/bin/nologin"
iocage exec test10 chown -R jackett:jackett /usr/local/share/Jackett /config
iocage exec test10 mkdir /usr/local/etc/rc.d
cp ${SCRIPT_DIR}/jails/test10/includes/jackett.rc /mnt/${global_dataset_iocage}/jails/test10/root/usr/local/etc/rc.d/jackett
iocage exec test10 chmod u+x /usr/local/etc/rc.d/jackett
iocage exec test10 sysrc "jackett_enable=YES"
iocage exec test10 service jackett restart