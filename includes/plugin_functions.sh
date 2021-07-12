#!/usr/local/bin/bash
# shellcheck disable=SC1003

initplugin() {
	# as this function is called from plugins we need to re-enable strict mode
	# shellcheck source=libstrict.sh
	source "${SCRIPT_DIR}/includes/libstrict.sh"
	strict::mode

	local jail_name plugin varlist linkplugin linkvarlist value val linkvalue linkval globalvarlist
	jail_name=${1:?}
	plugin=${jail_name}_plugin
	varlist=$(jq -r '.jailman | .variables | .options | .[]' "${global_dataset_iocage}/jails/${jail_name}/${!plugin}.json")
	global_varlist=$(jq -r '.jailman | .variables | .options | .[]' "${SCRIPT_DIR}/includes/global.json")
	
	for var in ${varlist:-} ${global_varlist:-}
	do
		value="${jail_name}_$var"
		val=${!value:-}
		declare -g "${var}=${val}"
		
		linkplugin=${val}_plugin
		if [[ "${var}" =~ ^link_.* ]] && [[ -n "${val}" ]] && [[ -n "${!linkplugin}" ]];
		then
			# shellcheck disable=SC2143
			if [ -z "$(iocage list -q | grep "${val}")" ];
			then
				echo "ERR: a link to $val was requested but no plugin was found for it"
			else
				linkvarlist=$(jq -r '.jailman | .variables | .options | .[]' "${global_dataset_iocage}/jails/${val}/${!linkplugin}.json" || echo "")
				for linkvar in ${linkvarlist:-} ${global_varlist:-}
				do
					linkvalue="${val}_${linkvar}"
					linkval=${!linkvalue:-}
					declare -g "${var}_${linkvar}=${linkval}"
				done
			fi
		fi
	done

	declare -g "root=${global_dataset_iocage}/jails/${jail_name}/root"
	declare -g "plugin_dir=${global_dataset_iocage}/jails/${jail_name}/plugin/jailman/"
	declare -g "includes_dir=${plugin_dir}/includes"

	if [ -f "/mnt/${global_dataset_config}/${1}/INSTALLED" ]; then
	    echo "Reinstall detected..."
		declare -g reinstall="true"
	elif [ "$(ls -A "/mnt/${global_dataset_config}/${1}/")" ]; then
	    echo "ERROR, No valid install detected in config directory but files present"
		exit 1
	else
		echo "No reinstall flag detected, continuing normal install"
		declare -g reinstall="false"
	fi

	if [ -z "${ip4_addr}" ]; then
		DEFAULT_IF=$(iocage exec "${jail_name}" route get default | awk '/interface/ {print $2}')
		declare -g "jail_ip=$(iocage exec "${jail_name}" ifconfig "$DEFAULT_IF" | awk '/inet/ { print $2 }')"
	else
		declare -g "jail_ip=${ip4_addr%/*}"
	fi
}
export -f initplugin

cleanupplugin() {
	if [ -z "${1:-}" ]; then
		echo "No jail to clean"
	else
		traefik_proxy="${1:-}_traefik_proxy"
		if [ -n "${!traefik_proxy:-}" ]; then
			echo "removing remains..."
			rm -f /mnt/"${global_dataset_config}"/"${traefik_proxy}"/dynamic/"${1:-}".toml
			rm -f /mnt/"${global_dataset_config}"/"${traefik_proxy}"/dynamic/"${1:-}"_auth_basic.toml
			rm -f /mnt/"${global_dataset_config}"/"${traefik_proxy}"/dynamic/"${1:-}"_auth_forward.toml
		fi
	fi
}
export -f cleanupplugin

summadd() {
	local jail_name="${1:-}"
	local message="${2:-}"
	echo "${message}"
	echo "${message}" >> "${SCRIPT_DIR}/summaries/${starttime}.txt"
	if [ -n "${jail_name}" ]; then
		iocage exec "${1}" echo "${message}" >> "/root/PLUGIN_INFO"
	fi
}
export -f summadd

exitplugin() {
	# as this function is called from plugins we need to re-enable strict mode
	# shellcheck source=libstrict.sh
	source "${SCRIPT_DIR}/includes/libstrict.sh"
	strict::mode
	local jail_name status_message plugin_name traefik_service_port traefik_includes traefik_status traefik_root traefik_tmp traefik_dyn

	jail_name=${1:?}
	status_message=${2:-}
	plugin_name=${jail_name}_plugin
	traefik_service_port="$(jq -r '.jailman | .traefik_service_port' "${global_dataset_iocage}/jails/${jail_name}/${!plugin_name}.json")"
	traefik_status=""

	# Check if the jail is compatible with Traefik and copy the right default-config for the job.
	if [ "${!plugin_name}" == "traefik" ]; then
		traefik_includes="${global_dataset_iocage}/jails/${jail_name}/plugin/jailman/includes"
		traefik_root=/mnt/"${global_dataset_config}"/"${jail_name}"
		traefik_tmp=${traefik_root}/temp
		traefik_dyn=${traefik_root}/dynamic
		traefik_status="preinstalled"
	elif [ -n "${traefik_proxy}" ]; then
		traefik_includes="${global_dataset_iocage}/jails/${traefik_proxy}/plugin/jailman/includes"
		traefik_root=/mnt/"${global_dataset_config}"/"${traefik_proxy}"
		traefik_tmp=${traefik_root}/temp
		traefik_dyn=${traefik_root}/dynamic
		echo "removing old traefik config..."
		rm -f "${traefik_dyn}/${jail_name}.toml"
		rm -f "${traefik_dyn}/${jail_name}_auth_basic.toml"
		rm -f "${traefik_dyn}/${jail_name}_auth_forward.toml"
		if [ -z "${domain_name}" ]; then
			echo "domain_name required for connecting to traefik... please add domain_name to config.yml"
		elif [ -f "${plugin_dir}/traefik_custom.toml" ]; then
			echo "Found custom traefik configuration... Copying to traefik..."
			cp "${plugin_dir}/traefik_custom.toml" "${traefik_tmp}/${jail_name}.toml"
			traefik_status="success"
		elif [ -f "${includes_dir}/traefik_custom.toml" ]; then
			echo "Found default traefik configuration for this plugin... Copying to traefik..."
			cp "${includes_dir}/traefik_custom.toml" "${traefik_tmp}/${jail_name}.toml"
			traefik_status="preinstalled"
		elif [ -z "${traefik_service_port}" ]; then
			echo "Can't connect this jail to traefik... Please add a traefik_service_port to this jail in config.yml..."
		else
			echo "No custom traefik configuration found, using default..."
			cp "${traefik_includes}/default.toml" "${traefik_tmp}/${jail_name}.toml"
			traefik_status="preinstalled"
		fi
	else
		echo "Traefik-connection not enabled... Skipping connecting this jail to traefik"
	fi

	# If the default config requires post-processing (it always does except for user-custom config in /config), do the post processing.
	if [ "${traefik_status}" = "preinstalled" ]; then
		# replace placeholder values.
		# also replace auth related placeholders, because they can be part of custom config files
		sed -i '' \
			-e "s|placeholderdashboardhost|${domain_name//&/\\&}|" \
			-e "s|placeholdername|${1//&/\\&}|" \
			-e "s|placeholderurl|${jail_ip}:${traefik_service_port}|" \
			-e "s|placeholderusers|${traefik_auth_basic//&/\\&}|" \
			-e "s|placeholderauthforward|${traefik_auth_forward//&/\\&}|" \
			"${traefik_tmp}/${jail_name}.toml"

		if [ -n "${traefik_auth_forward}" ] && [ -n "${traefik_auth_basic}" ]; then
			echo "Cannot setup traefik with both basic AND forward auth. Please pick one only."
		elif [ -n "${traefik_auth_basic}" ]; then
			echo "Adding basic auth to Traefik for jail ${jail_name}"
			users=""
			for cred in ${traefik_auth_basic}
			do
				username=$(echo "${cred}" | cut -d: -f1)
				password=$(echo "${cred}" | cut -d: -f2)
				password=$(openssl passwd -apr1 "${password}")
				users="${users:-} ${username}:${password}"
			done
			# shellcheck disable=SC2001
			users=$(echo "$users" | sed -e 's/^[[:space:]]*//')
			users="$(sed 's/[^[:space:]]\{1,\}/"&"/g;s/ /,/g' <<<"${users}")"
			cp "${traefik_includes}/default_auth_basic.toml" "${traefik_tmp}/${jail_name}_auth_basic.toml"
			sed -i '' \
				-e "s|placeholdername|${1//&/\\&}|" \
				-e "s|placeholderusers|${users//&/\\&}|" \
				"${traefik_tmp}/${jail_name}_auth_basic.toml"
			mv "${traefik_tmp}/${jail_name}_auth_basic.toml" "${traefik_dyn}/${jail_name}_auth_basic.toml"
			sed -i '' "s|\"retry\"|\"retry\",\"${1//&/\\&}-basic-auth\"|" "${traefik_tmp}/${jail_name}.toml"
			traefik_status="success"
		elif [ -n "${traefik_auth_forward}" ]; then
			echo "Adding forward auth to Traefik for jail ${jail_name}"
			cp "${traefik_includes}/default_auth_forward.toml" "${traefik_tmp}/${jail_name}_auth_forward.toml"
			sed -i '' \
				-e "s|placeholdername|${1//&/\\&}|" \
				-e "s|placeholderauthforward|${traefik_auth_forward//&/\\&}|" \
				"${traefik_tmp}/${jail_name}_auth_forward.toml"
			mv "${traefik_tmp}/${jail_name}_auth_forward.toml" "${traefik_dyn}/${jail_name}_auth_forward.toml"
			sed -i '' "s|\"retry\"|\"retry\",\"${1//&/\\&}-forward-auth\"|" "${traefik_tmp}/${jail_name}.toml"
			traefik_status="success"
		else
			echo "No auth specified, setting up traefik without auth..."
			traefik_status="success"
		fi
		mv "${traefik_tmp}/${jail_name}.toml" "${traefik_dyn}/${jail_name}.toml"
	fi

	# Add a file to flag the jail is INSTALLED and thus trigger reinstall on next install
	echo "DO NOT DELETE THIS FILE" >> "/mnt/${global_dataset_config}/${jail_name}/INSTALLED"
	
	summadd "${jail_name}" ""
	summadd "${jail_name}" "----------"
	summadd "${jail_name}" ""
	summadd "${jail_name}" "Summary for: ${jail_name}"
	summadd "${jail_name}" "Jail ${jail_name} installed successfully using plugin ${!plugin_name}."

	# Pick the right success message to hint to user how to connect to the jail
	if [ "${traefik_status}" = "success" ]; then
		summadd "${jail_name}" "Your jail ${jail_name} running ${!plugin_name} is now accessible via Traefik at https://${domain_name}"
	elif [[ -n "${status_message}" ]]; then
		summadd "${jail_name}" " ${status_message}"
	elif [ -n "${traefik_service_port}" ]; then
		summadd "${jail_name}" "Your jail ${jail_name} running ${!plugin_name} is now accessible at http://${jail_ip}:${traefik_service_port}"
	else
		summadd "${jail_name}" "Please consult the wiki for instructions connecting to your newly installed jail"
	fi
}
export -f exitplugin

