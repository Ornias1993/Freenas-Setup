#!/usr/local/bin/bash

# Important defines:
export SCRIPT_NAME=$(basename $(test -L "${BASH_SOURCE[0]}" && readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}"));
export SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
echo "Working directory for jailman.sh is: ${SCRIPT_DIR}"

#Includes
source ${SCRIPT_DIR}/global.sh

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Auto Update
BRANCH="dev"
gitupdate ${BRANCH}

# If no option is given, point to the help menu
if [ $# -eq 0 ]
then
        echo "Missing options!"
        echo "(run $0 -h for help)"
        echo ""
        exit 0
fi

# Go through the options and put the jails requested in an array
unset -v sub
while getopts ":i:r:u:d:g:h" opt
   do
     case $opt in
        i ) installjails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                installjails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
        r ) redojails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                redojails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
        u ) updatejails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                updateljails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
        d ) destroyjails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                deletejails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
		g ) upgradejails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                upgradejails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
		h ) 
			echo "Usage:"
            echo "$0 -i "
            echo "$0 -r "
            echo "$0 -u "
            echo "$0 -d  "
            echo "$0 -g "
            echo ""
            echo "   -i to install jails, listed by name, space seperated like this: jackett plex sonarr"
            echo "   -r to reinstall jails, listed by name, space seperated like this: jackett plex sonarr"
			echo "   -u to update jails, listed by name, space seperated like this: jackett plex sonarr"
            echo "   -d to destroy jails, listed by name, space seperated like this: jackett plex sonarrt"
            echo "   -g to upgrade jails, listed by name, space seperated like this: jackett plex sonarr"
            echo "   -h help (this output)"
			exit 0
            ;;
		? ) echo "Error: Invalid option was specified -$OPTARG"
			exit 0
			;;
     esac
done

# Parse the Config YAML
eval $(parse_yaml config.yml)

# Check and Execute requested jail destructions
if [ ${#destroyjails[@]} -eq 0 ]; then 
	echo "No jails to destroy"
else
	echo "jails to destroy ${destroyjails[@]}"
	for jail in "${destroyjails[@]}"
	do
		echo "destroying $jail"
		iocage destroy -f $jail
	done

fi

# Check and Execute requested jail Installs
if [ ${#installjails[@]} -eq 0 ]; then 
	echo "No jails to install"
else
	echo "jails to install ${installjails[@]}"
	for jail in "${installjails[@]}"
	do
		if [ -f "${SCRIPT_DIR}/jails/$jail/install.sh" ]
		then
			echo "Installing $jail"
			jailcreate $jail && ${SCRIPT_DIR}/jails/$jail/install.sh
		else
			echo "Missing install script for $jail in ${SCRIPT_DIR}/jails/$jail/install.sh"
		fi
	done
fi

# Check and Execute requested jail Reinstalls
if [ ${#redojails[@]} -eq 0 ]; then 
	echo "No jails to ReInstall"
else
	echo "jails to reinstall ${redojails[@]}"
	for jail in "${redojails[@]}"
	do
		if [ -f "${SCRIPT_DIR}/jails/$jail/install.sh" ]
		then
			echo "Reinstalling $jail"
			iocage destroy -f $jail && jailcreate $jail && ${SCRIPT_DIR}/jails/$jail/install.sh
		else
			echo "Missing install script for $jail in ${SCRIPT_DIR}/jails/$jail/update.sh"
		fi
	done
fi


# Check and Execute requested jail Updates
if [ ${#updatejails[@]} -eq 0 ]; then 
	echo "No jails to Update"
else
	echo "jails to update ${updatejails[@]}"
	for jail in "${updatejails[@]}"
	do
		if [ -f "${SCRIPT_DIR}/jails/$jail/update.sh" ]
		then
			echo "Updating $jail"
			iocage update $jail && iocage exec $jail "pkg update && pkg upgrade -y" && ${SCRIPT_DIR}/jails/$jail/update.sh
			iocage restart $jail
		else
			echo "Missing update script for $jail in ${SCRIPT_DIR}/jails/$jail/update.sh"
		fi
	done
fi

# Check and Execute requested jail Upgrades
if [ ${#upgradejails[@]} -eq 0 ]; then 
	echo "No jails to Upgrade"
else
	echo "jails to update ${upgradejails[@]}"
	for jail in "${upgradejails[@]}"
	do
		if [ -f "${SCRIPT_DIR}/jails/$jail/update.sh" ]
		then
			echo "Currently Upgrading is not yet included in this script."
		else
			echo "Missing update script for $jail in ${SCRIPT_DIR}/jails/$jail/update.sh"
		fi
	done
fi
