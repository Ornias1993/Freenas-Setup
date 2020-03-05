#!/usr/local/bin/bash

export SCRIPT_NAME=$(basename $(test -L "${BASH_SOURCE[0]}" && readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}"));
export SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
echo "Working directory for jailman.sh is: ${SCRIPT_DIR}"

source ${SCRIPT_DIR}/global.sh
eval $(parse_yaml config.yml)


if [ $# -eq 0 ]
then
        echo "Missing options!"
        echo "(run $0 -h for help)"
        echo ""
        exit 0
fi


unset -v sub
while getopts ":i:r:u:d:" opt
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
        d ) deletejails=("$OPTARG")
            until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
                deletejails+=($(eval "echo \${$OPTIND}"))
                OPTIND=$((OPTIND + 1))
            done
            ;;
     esac
done

if [ ${#deletejails[@]} -eq 0 ]; then 
	echo "No jails to destroy"
else
	echo "jails to destroy ${deletejails[@]}"
	for jail in "${deletejails[@]}"
	do
		echo "destroy $jail"

	done

fi

if [ ${#installjails[@]} -eq 0 ]; then 
	echo "No jails to install"
else
	echo "jails to install ${installjails[@]}"
	for jail in "${installjails[@]}"
	do
		if [ -f "${SCRIPT_DIR}/jails/$jail/install.sh" ]
		then
			echo "Installing $jail"
			./jailcreate.sh $jail && ./jails/$jail/install.sh
		else
			echo "Missing install script for $jail in ${SCRIPT_DIR}/jails/$jail/install.sh"
		fi
	done
fi

if [ ${#redojails[@]} -eq 0 ]; then 
	echo "No jails to ReInstall"
else
	echo "jails to reinstall ${redojails[@]}"
	for jail in "${redojails[@]}"
	do
		echo "Reinstalling $jail"

	done
fi

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