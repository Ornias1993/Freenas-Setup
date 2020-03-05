#!/usr/local/bin/bash

echo "Checking config..."
jailname="jail_${1}"
jailpkgs="jail_${1}_pkgs"
jailinterfaces="jail_${1}_interfaces"
jailip4="jail_${1}_ip4_addr"
jailgateway="jail_${1}_gateway"

if [ -z "${!jailinterfaces}" ]; then 
	jailinterfaces="vnet0:bridge0"
fi

if [ -z "${!jailname}" ]; then 
	echo "ERROR, jail not defined in config.yml"
	exit 1
else
	echo "Creating jail for $1"
	pkgs="$(sed 's/[^[:space:]]\{1,\}/"&"/g;s/ /,/g' <<<"${!jailpkgs} ${global_jails_pkgs}")"
	echo '{"pkgs":['${pkgs}']}' > /tmp/pkg.json
	iocage create -n "${1}" -p /tmp/pkg.json -r ${global_jails_version} interfaces="${!jailinterfaces}" ip4_addr="vnet0|${!jailip4}" defaultrouter="${!jailgateway}" vnet="on" allow_raw_sockets="1" boot="on"
	rm /tmp/pkg.json
	echo "creating jail config directory"
	iocage exec $1 mkdir -p /config
	if [ ! -d "${global_dataset_config}/$1" ]; then
	echo "Config dataset does not exist... Creating... ${global_dataset_config}/$1"
	zfs create ${global_dataset_config}/$1
	fi
	iocage fstab -a $1 /mnt/${global_dataset_config}/$1 /config nullfs rw 0 0
	echo "Jail creation completed for $1"
fi