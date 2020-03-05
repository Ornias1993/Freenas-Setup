#!/usr/local/bin/bash

export -p
echo "subshell test"
echo ${jail_test_pkgs}

#echo '{"pkgs":['${jail_test_pkgs}']}' > /tmp/pkg.json
#iocage create -n "${jail_test_name}" -p /tmp/pkg.json -r ${global_jails_version} interfaces="${jail_test_interfaces}" ip4_addr="vnet0|${jail_test_ip4_addr}" defaultrouter="${jail_test_gateway}" vnet="on" allow_raw_sockets="1" boot="on"
#rm /tmp/pkg.json
#iocage exec $jail_test_name mkdir -p /config
#iocage fstab -a $jail_test_name /mnt/tank/apps/$jail_test_name /config nullfs rw 0 0