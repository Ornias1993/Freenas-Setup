#!/usr/local/bin/bash
# This file contains the update script for unifi
# Unifi Controller is updated through pkg, Unifi-Poller is not. This script updates Unifi-Poller

JAIL_NAME="unifi"
FILE_NAME=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .name")
DOWNLOAD=$(curl -s https://api.github.com/repos/unifi-poller/unifi-poller/releases/latest | jq -r ".assets[] | select(.name | contains(\"amd64.txz\")) | .browser_download_url")

# Check to see if there is an update.
# shellcheck disable=SC2154
if [[ -f /mnt/"${global_dataset_config}"/"${JAIL_NAME}"/"${FILE_NAME}" ]]; then
  echo "Unifi-Poller is up to date."
  exit 1
else
  # Download and install the package
  iocage exec "${JAIL_NAME}" fetch -o /config "${DOWNLOAD}"
  iocage exec "${JAIL_NAME}" pkg install -qy /config/"${FILE_NAME}"
  iocage exec "${JAIL_NAME}" service unifi restart
  iocage exec "${JAIL_NAME}" service unifi_poller restart
fi

echo "Update complete!"
