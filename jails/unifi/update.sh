#!/usr/local/bin/bash
# This file contains the update script for unifi

JAIL_NAME="unifi"
FILE="unifi-poller-2.0.0_760.amd64.txz"
FILE_VERSION="v2.0.0"
echo "Downloading Unifi-Poller and verifying checksum..."
iocage exec "${JAIL_NAME}" "fetch -o /tmp --no-verify-peer https://github.com/unifi-poller/unifi-poller/releases/download/${FILE_VERSION}/${FILE} https://github.com/unifi-poller/unifi-poller/releases/download/${FILE_VERSION}/checksums.sha256.txt" 
iocage exec "${JAIL_NAME}" "grep unifi-poller-2.0.0_760.amd64.txz /tmp/checksums.sha256.txt > /tmp/unifi-poller-2.0.0_760.amd64.sha256"
if ! iocage exec "${JAIL_NAME}" "cd /tmp && shasum -a 256 -c /tmp/unifi-poller-2.0.0_760.amd64.sha256"; then
  echo "Download failed checksum. Exiting..."
  exit 1
fi

echo "Download complete, installing Unifi-Poller..."
iocage exec "${JAIL_NAME}" pkg install /tmp/unifi-poller-2.0.0_760.amd64.txz
iocage exec "${JAIL_NAME}" mv /usr/local/etc/rc.d/unifi-poller /usr/local/etc/rc.d/unifi_poller

echo "Starting Unifi-Controller and Unifi-Poller..."
iocage exec "${JAIL_NAME}" service unifi restart
iocage exec "${JAIL_NAME}" service unifi_poller restart