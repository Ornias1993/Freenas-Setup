#!/usr/local/bin/bash
# shellcheck disable=SC2145,SC2015
#Set to anything other than "true" to disable auto-update
AUTOUPDATE="true"

#setup logging
LOG_FILE=/var/log/jailman.log
exec > >(tee ${LOG_FILE}) 2>&1

# Important defines:
SCRIPT_NAME="$(basename "$(test -L "${BASH_SOURCE[0]}" && readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")");"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
starttime=$(date +%s)
export starttime
export SCRIPT_NAME
export SCRIPT_DIR

# shellcheck source=includes/libstrict.sh
source "${SCRIPT_DIR}/includes/libstrict.sh"

strict::mode

echo "Working directory for jailman.sh is: ${SCRIPT_DIR}"

#Includes
# shellcheck source=includes/init_functions.sh
source "${SCRIPT_DIR}/includes/init_functions.sh"

# shellcheck source=includes/global_functions.sh
source "${SCRIPT_DIR}/includes/global_functions.sh"

# shellcheck source=includes/plugin_functions.sh
source "${SCRIPT_DIR}/includes/plugin_functions.sh"

touch "${SCRIPT_DIR}/summaries/${starttime}.txt"

usage() {
	echo "Usage:"
	echo "$0"
	echo "-h"
	echo "   Help (this output)"
	echo "-i [_jailname] [_jailname1] ... [_jailnameN]"
	echo "   Install jails"
	echo "-r [_jailname] [_jailname1] ... [_jailnameN]"
	echo "   Reinstall jails (destroy then create)"
	echo "-u [_jailname] [_jailname1] ... [_jailnameN]"
	echo "   Run jail upgrade script"
	echo "-d [_jailname] [_jailname1] ... [_jailnameN]"
	echo "   Destroy jails"
	echo "-n [_jailname] [_jailname1] ... [_jailnameN]"
	echo "   NUKE/Remove all /config data for a specified jail"
	echo "-g [_jailname] [_jailname1] ... [_jailnameN]"
	echo "    Update the jail and any packages inside"
	echo ""
	echo " Examples:"
	echo ""
	echo "    # $0 -i plex"
	echo "      Install plex"
	echo ""
	echo "    # $0 -d plex transmission"
	echo "      Uninstall (DESTROY) plex and transmission"
}

# Check for root privileges
if ! [ "$(id -u)" = 0 ]; then
	echo "This script must be run with root privileges"
	exit 1
fi

# Auto Update
if [ "${AUTOUPDATE}" == "true" ]
then
	gitupdate
fi

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
args=("$@")
arglen=${#args[@]}

installjails=()
redojails=()
updatejails=()
destroyjails=()
nukedata=()
upgradejails=()
while getopts ":i:r:u:d:n:g:h" opt
do
	#Shellcheck on wordsplitting will be disabled. Wordsplitting can't happen, because it's already split using OPTIND.
	case $opt in
		i ) installjails=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				installjails+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		r ) redojails=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				redojails+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		u ) updatejails=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				updatejails+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		d ) destroyjails=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				destroyjails+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		n ) nukedata=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				nukedata+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		g ) upgradejails=("$OPTARG")
			until (( OPTIND > arglen )) || [[ ${args[$OPTIND-1]} =~ ^-.* ]]; do
				upgradejails+=("${args[$OPTIND-1]}")
				OPTIND=$((OPTIND + 1))
			done
			;;
		h ) 
			usage
			exit 3
			;;
		* ) echo "Error: Invalid option was specified -$OPTARG"
			usage
			exit 3
			;;
	esac
done

# Trick iocage into activating based on TrueNAS system dataset
iocage list >> /dev/null

# Color code shortcuts
normcol='\033[m'
warncol='\033[33m'
errcol='\033[31m'

# auto detect iocage install location
global_dataset_iocage=$(zfs get -H -o value mountpoint "$(iocage get -p)"/iocage)
export global_dataset_iocage

# load all config
load_config

if [ "${global_version:-}" != "1.3" ]; then
	echo "You are using old config.yml syntax."
    echo "Please check the wiki for required changes"
	exit 1
fi

# Check and Execute requested jail destructions
if [ ${#destroyjails[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "jails to destroy: ${destroyjails[@]}"
	for jail in "${destroyjails[@]}"
	do
		iocage destroy -fR "${jail}" && summadd "" "destroyed ${jail}" || summadd "" "destroy failed for ${jail}"
		cleanupplugin "${jail}"
	done
fi

# Check and Execute requested jail destructions
if [ ${#nukedata[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "Jail-datasets to Nuke: ${nukedata[@]}"
	echo -e "${errcol}-n stands for NUKE for a reason."
	echo -e "We HIGHLY recommend you NOT to use this feature, but destroy any data(sets) yourself, manually. ${normcol}"
	for jail in "${nukedata[@]}"
	do
		read -p "Are you sure you want to destroy ALL data for the ${jail} jail? " -n 1 -r
		echo    # (optional) move to a new line
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
			zfs destroy "${global_dataset_config}/${jail}" && summadd "" "Nuked dataset for ${jail}" || summadd "" "Nuking dataset failed for ${jail}"
		fi
	done
fi

# Check and Execute requested jail Installs
if [ ${#installjails[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "jails to install: ${installjails[@]}"
	for jail in "${installjails[@]}"
	do
		plugin=${jail}_plugin
		if [ -z "${!plugin:-}" ]
		then
			echo "Config for ${jail} in config.yml incorrect. Please check your config."
			exit 1
		else
			jailcreate "${jail}" "${!plugin}" || summadd "" "Install failed for ${jail}"
		fi
		if [ -f "${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh" ]
		then
			# check plugin install script for syntax errors
			plugin_installer="${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh"
			if ! bash -n "${plugin_installer}" 2>/dev/null; then
				echo -e "${errcol}ERR: plugin install script at ${plugin_installer} has syntax errors."
				echo "Please report this issue to the maintainer according to docs/CODEOWNERS."
				echo -e "Will not continue.${normcol}"
				exit 1
			fi

			echo "Installing $jail"
			"${global_dataset_iocage}"/jails/"${jail}"/plugin/jailman/finish_install.sh "${jail}" || summadd "" "Install failed for ${jail}"
		else
			echo "Missing plugin ${!plugin} for $jail in ${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh"
			exit 1
		fi
	done
fi

# Check and Execute requested jail Reinstalls
if [ ${#redojails[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "jails to reinstall: ${redojails[@]}"
	for jail in "${redojails[@]}"
	do
		plugin=${jail}_plugin
		if [ -z "${!plugin:-}" ]
		then
			echo "Config for ${jail} in config.yml incorrect. Please check your config."
			exit 1
		else
			iocage destroy -fR "${jail}" || true
			cleanupplugin "${jail}" || true
			jailcreate "${jail}" "${!plugin}" || summadd "" "Reinstall failed for ${jail}"
		fi
		if [ -f "${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh" ]
		then
			# check plugin install script for syntax errors
			plugin_installer="${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh"
			if ! bash -n "${plugin_installer}" 2>/dev/null; then
				echo -e "${errcol}ERR: plugin install script at ${plugin_installer} has syntax errors."
				echo "Please report this issue to the maintainer according to docs/CODEOWNERS."
				echo -e "Will not continue.${normcol}"
				exit 1
			fi

			echo "Reinstalling $jail"
			"${global_dataset_iocage}"/jails/"${jail}"/plugin/jailman/finish_install.sh "${jail}" || summadd "" "Reinstall failed for ${jail}"
		else
			echo "Missing plugin ${!plugin} for $jail in ${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh"
			exit 1
		fi
	done
fi

# Check and Execute requested jail Updates
if [ ${#updatejails[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "jails to update: ${updatejails[@]}"
	for jail in "${updatejails[@]}"
	do
		plugin=${jail}_plugin
		if [ -z "${!plugin:-}" ]
		then
			echo "Config for ${jail} in config.yml incorrect. Please check your config."
			exit 1
		else
			iocage update "${jail}" || summadd "" "Update failed for ${jail}"
		fi
		if [ -f "${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_install.sh" ]
		then
			# check plugin install script for syntax errors
			plugin_updater="${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_update.sh"
			if ! bash -n "${plugin_updater}" 2>/dev/null; then
				echo "ERR: plugin update script at ${plugin_updater} has syntax errors."
				echo "Please report this issue to the maintainer according to docs/CODEOWNERS."
				echo "Will not continue."
				exit 1
			fi

			echo "Updating $jail"
			"${global_dataset_iocage}"/jails/"${jail}"/plugin/jailman/finish_update.sh "${jail}" || summadd "" "Update failed for ${jail}"
			iocage restart "${jail}"
		else
			echo "Missing plugin ${!plugin} for $jail in ${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_update.sh"
			exit 1
		fi
	done
fi

# Check and Execute requested jail Upgrades
if [ ${#upgradejails[@]} -gt 0 ]; then
	summadd "" ""
	summadd "" "jails to upgrade: ${upgradejails[@]}"
	for jail in "${upgradejails[@]}"
	do
		plugin=${jail}_plugin
		if [ -z "${!plugin:-}" ]
		then
			echo "Config for ${jail} in config.yml incorrect. Please check your config."
			exit 1
		else
			echo "Currently Upgrading is not yet included in this script."
		fi
		if [ -f "${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_upgrade.sh" ]
		then
			# check plugin install script for syntax errors
			plugin_upgrader="${global_dataset_iocage}/jails/${jail}/plugin/jailman/finish_upgrade.sh"
			if ! bash -n "${plugin_upgrader}" 2>/dev/null; then
				echo "ERR: plugin upgrade script at ${plugin_upgrader} has syntax errors."
				echo "Please report this issue to the maintainer according to docs/CODEOWNERS."
				echo "Will not continue."
				exit 1
			fi

			echo "Currently Upgrading is not yet included in this script."
		else
			echo "Currently Upgrading is not yet included in this script."
			exit 1
		fi
	done
fi

summadd "" ""
summadd "" ""
echo ""
echo ""
echo "Jailman run finished, installation summary: "
cat "${SCRIPT_DIR}/summaries/${starttime}.txt"

