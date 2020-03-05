echo '{"pkgs":["mono","ca_root_nss","unzip","sqlite3","nano"]}' > /tmp/pkg.json
iocage create -n "ombi" -p /tmp/pkg.json -r 11.3-RELEASE interfaces="vnet0:bridge31" ip4_addr="vnet0|192.168.31.27/24" defaultrouter="192.168.31.1" vnet="on" allow_raw_sockets="1" boot="on"
rm /tmp/pkg.json
iocage exec ombi mkdir -p /config
iocage fstab -a ombi /mnt/tank/apps/ombi /config nullfs rw 0 0
iocage exec ombi ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec ombi "fetch https://github.com/tidusjar/Ombi/releases/download/v2.2.1/Ombi.zip -o /usr/local/share"
iocage exec ombi "unzip -d /usr/local/share /usr/local/share/Ombi.zip"
iocage exec ombi mv /usr/local/share/Release /usr/local/share/ombi
iocage exec ombi rm /usr/local/share/Ombi.zip
 
if [ -f "/config/Ombi.sqlite" ];
then
   echo "Ombi.sqlite exist."
else
   echo "Ombi.sqlite does not exist, creating..." >&2
   iocage exec ombi sqlite3 /config/Ombi.sqlite "create table aTable(field1 int); drop table aTable;"
   iocage exec ombi mkdir -p /config/Backups
fi

iocage exec ombi ln -s /config/Ombi.sqlite /usr/local/share/ombi/Ombi.sqlite
iocage exec ombi ln -s /config/Backups /usr/local/share/ombi/Backups
iocage exec ombi "pw user add ombi -c ombi -u 819 -d /nonexistent -s /usr/bin/nologin"
iocage exec ombi chown -R ombi:ombi /usr/local/share/ombi /config
iocage exec ombi mkdir /usr/local/etc/rc.d
cp ../includes/ombi-conf/ombi.rc /mnt/tank/iocage/jails/ombi/root/usr/local/etc/rc.d/ombi
iocage exec ombi chmod u+x /usr/local/etc/rc.d/ombi
iocage exec ombi sysrc ombi_enable=YES
iocage exec ombi service ombi start