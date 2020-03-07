#!/usr/local/bin/bash
# shellcheck disable=SC1003

# yml Parser function
# Based on https://gist.github.com/pkuczynski/8665367
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("export %s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# automatic update function
gitupdate() {
echo "checking for updates using Branch: $1"
git fetch
git update-index -q --refresh
CHANGED=$(git diff --name-only origin/$1)
if [ ! -z "$CHANGED" ];
then
    echo "script requires update"
    git reset --hard
    git checkout $1
    git pull
    echo "script updated"
    exit 1
else
    echo "script up-to-date"
fi
}

jailcreate() {
echo "Checking config..."
jailname="${1}"
jailpkgs="${1}_pkgs"
jailinterfaces="${1}_interfaces"
jailip4="${1}_ip4_addr"
jailgateway="${1}_gateway"
jaildhcp="${1}_dhcp"
setdhcp=${!jaildhcp}

if [ -z "${!jailinterfaces}" ]; then 
	jailinterfaces="vnet0:bridge0"
else
	jailinterfaces=${!jailinterfaces}
fi

if [ -z "${setdhcp}" ] && [ -z "${!jailip4}" ] && [ -z "${!jailgateway}" ]; then 
	echo 'no network settings specified in config.yml, defaulting to dhcp="on"'
	setdhcp="on"
fi

if [ -z "${!jailname}" ]; then 
	echo "ERROR, jail not defined in config.yml"
	exit 1
else
	echo "Creating jail for $1"
	pkgs="$(sed 's/[^[:space:]]\{1,\}/"&"/g;s/ /,/g' <<<"${!jailpkgs} ${global_jails_pkgs}")"
	echo '{"pkgs":['${pkgs}']}' > /tmp/pkg.json
	if [ "${setdhcp}" == "on" ]
	then
		if ! iocage create -n "${1}" -p /tmp/pkg.json -r ${global_jails_version} interfaces="${jailinterfaces}" dhcp="on" vnet="on" allow_raw_sockets="1" boot="on"
		then
			echo "Failed to create jail"
			exit 1
		fi
	else
		if ! iocage create -n "${1}" -p /tmp/pkg.json -r ${global_jails_version} interfaces="${jailinterfaces}" ip4_addr="vnet0|${!jailip4}" defaultrouter="${!jailgateway}" vnet="on" allow_raw_sockets="1" boot="on"
		then
			echo "Failed to create jail"
			exit 1
		fi
		
	fi

	rm /tmp/pkg.json
	echo "creating jail config directory"
	iocage exec $1 mkdir -p /config

	if [ ! -d "/mnt/${global_dataset_config}" ]; then
		echo "Config root dataset does not exist... Creating... ${global_dataset_config}"
		zfs create ${global_dataset_config}
	fi
	
	if [ ! -d "/mnt/${global_dataset_config}/$1" ]; then
		echo "Config dataset does not exist... Creating... ${global_dataset_config}/$1"
		zfs create ${global_dataset_config}/$1
	fi
	
	iocage fstab -a $1 /mnt/${global_dataset_config}/$1 /config nullfs rw 0 0
	echo "Jail creation completed for $1"
fi	
	
}

# $1 = jail name
# $2 = Dataset
# $3 = Target mountpoint
# $4 = fstab prefernces
export -f createmount() {
	if [ -z "$2" ] ; then
		echo "No Dataset specified"
		exit 1
	else
		if [ ! -d "/mnt/$2" ]; then
			echo "TV Shows dataset does not exist... Creating... $2"
			zfs create $2
		fi

		if [ -n "$1" ] && [ -n "$3" ]; then
			iocage exec $1 mkdir -p /mnt/$2
			if [ -n "$4" ]; then
				iocage fstab -a $1 /mnt/$2 $3 $4
			else
				iocage fstab -a $1 /mnt/$2 $3 nullfs rw 0 0
			fi
		else
			echo "Missing Jail Name or Mount target, skipping mount"
		fi

	fi
}
