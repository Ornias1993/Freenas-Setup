echo '{"pkgs":["bash","ca_root_nss","nano","py37-tkinter","py37-pip","py37-sqlite3","git"]}' > /tmp/pkg.json
iocage create -n "kms" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge10" ip4_addr="vnet0|192.168.10.43/24" defaultrouter="192.168.10.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec kms mkdir -p /config
iocage fstab -a kms /mnt/tank/apps/kms /config nullfs rw 0 0
iocage exec kms svn checkout https://github.com/SystemRage/py-kms/trunk/py-kms /usr/local/share/py-kms
iocage exec kms "pw user add kms -c kms -u 666 -d /nonexistent -s /usr/bin/nologin"
iocage exec kms chown -R kms:kms /usr/local/share/py-kms /config
iocage exec kms mkdir /usr/local/etc/rc.d
cp ../includes/py-kms-conf/py_kms.rc /mnt/tank/iocage/jails/kms/root/usr/local/etc/rc.d/py_kms
iocage exec kms chmod u+x /usr/local/etc/rc.d/py_kms
iocage exec kms sysrc "py_kms_enable=YES"
iocage exec kms service py_kms start