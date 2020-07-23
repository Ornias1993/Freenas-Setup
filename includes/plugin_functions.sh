#!/usr/local/bin/bash
# shellcheck disable=SC1003

initplugin() {
	# as this function is called from plugins we need to re-enable strict mode
	# shellcheck source=libstrict.sh
	source "${SCRIPT_DIR}/includes/libstrict.sh"
	strict::mode

	local jail_name plugin varlist linkplugin linkvarlist value val linkvalue linkval
	jail_name=${1:?}
	plugin=jail_${jail_name}_plugin

	varlist=$(jq -r '.jailman | .variables | .options | .[]' "${global_dataset_iocage}/jails/${jail_name}/${!plugin}.json")
	
	for var in ${varlist:-} ${global_jails_vars}
	do
		value="jail_${jail_name}_$var"
		val=${!value:-}
		declare -g "${var}=${val}"
		
		linkplugin=jail_${val}_plugin
		if [[ "${var}" =~ ^link_.* ]] && [[ -n "${val}" ]] && [[ -n "${!linkplugin}" ]];
		then
			# shellcheck disable=SC2143
			if [ -z "$(iocage list -q | grep "${val}")" ];
			then
				echo "ERR: a link to $val was requested but no plugin was found for it"
			else
				linkvarlist=$(jq -r '.jailman | .variables | .options | .[]' "${global_dataset_iocage}/jails/${val}/${!linkplugin}.json" || echo "")
				for linkvar in ${linkvarlist} ${global_jails_vars}
				do
					linkvalue="jail_${val}_${linkvar}"
					linkval=${!linkvalue:-}
					declare -g "${var}_${linkvar}=${linkval}"
				done
			fi
		fi
	done

	declare -g "jail_root=${global_dataset_iocage}/jails/${jail_name}/root"
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
	local jail_name=${1:?}

	link_traefik="jail_${jail_name}_link_traefik"
	link_traefik="${!link_traefik:-}"
	if [ -n "${link_traefik}" ]; then
		echo "removing remains..."
		rm -f /mnt/"${global_dataset_config}"/"${link_traefik}"/dynamic/"${jail_name}".toml
		rm -f /mnt/"${global_dataset_config}"/"${link_traefik}"/dynamic/"${jail_name}"_auth_basic.toml
		rm -f /mnt/"${global_dataset_config}"/"${link_traefik}"/dynamic/"${jail_name}"_auth_forward.toml
	fi
}
export -f cleanupplugin

exitplugin() {
	# as this function is called from plugins we need to re-enable strict mode
	# shellcheck source=libstrict.sh
	source "${SCRIPT_DIR}/includes/libstrict.sh"
	strict::mode
	local jail_name status_message plugin_name traefik_service_port traefik_includes traefik_status jailip4 jailgateway jaildhcp setdhcp traefik_root traefik_tmp traefik_dyn

	jail_name=${1:?}
	status_message=${2:-}
	plugin_name=jail_${jail_name}_plugin
	traefik_service_port="$(jq -r '.jailman | .traefik_service_port' "${global_dataset_iocage}/jails/${jail_name}/${!plugin_name}.json")"
	traefik_status=""
	jailip4="jail_${jail_name}_ip4_addr"
	jailgateway="jail_${jail_name}_gateway"
	jaildhcp="jail_${jail_name}_dhcp"
	setdhcp=${!jaildhcp:-}

	# Check if the jail is compatible with Traefik and copy the right default-config for the job.
	if [ -z "${link_traefik}" ]; then
		echo "Traefik-connection not enabled... Skipping connecting this jail to traefik"
	elif { [ -z "${setdhcp}" ]  || [ "${setdhcp:-}" == "on" ]; }  && [ -z "${!jailip4:-}" ] && [ -z "${!jailgateway:-}" ]; then
		echo "Warning: Traefik with DHCP requires that the jail's assigned IP adddress stays the same."
		echo "Please see the README for details on the setup."
	elif [[ ${link_traefik} =~ .*[[:space:]]$ ]]; then
		echo "Trailing whitespace in linked traefik jail '${link_traefik}'"
	else
		traefik_includes="${global_dataset_iocage}/jails/${link_traefik}/plugin/includes"
		traefik_root=/mnt/"${global_dataset_config}"/"${link_traefik}"
		traefik_tmp=${traefik_root}/temp
		traefik_dyn=${traefik_root}/dynamic
		if [ -z "${ip4_addr}" ] && [ "${setdhcp}" == "override" ] && [ -n "${jail_ip}" ]; then
			echo "Warning: Traefik with DHCP requires that the jail's assigned IP adddress stays the same."
			echo "Please see the README for details. If you cannot guarantee static IP assignment this will"
			echo "BREAK in unexpected ways and potentially expose services you did not intend to expose."
		fi
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
			users="$(sed 's/[^[:space:]]\{1,\}/"&"/g;s/ /,/g' <<<"${traefik_auth_basic}")"
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
	echo "Jail ${jail_name} using plugin ${!plugin_name}, installed successfully."

	# Pick the right success message to hint to user how to connect to the jail
	if [ "${traefik_status}" = "success" ]; then
		echo "Your jail ${jail_name} running ${!plugin_name} is now accessible via Traefik at https://${domain_name}"
	elif [[ -n "${status_message}" ]]; then
		echo " ${status_message}"
	elif [ -n "${traefik_service_port}" ]; then
		echo "Your jail ${jail_name} running ${!plugin_name} is now accessible at http://${jail_ip}:${traefik_service_port}"
	else
		echo "Please consult the wiki for instructions connecting to your newly installed jail"
	fi
}
export -f exitplugin

