#!/usr/local/bin/bash
# This file contains the update script for Plex

# Run different update procedures depending on Plex vs Plex Beta
# shellcheck disable=SC2154
if [ "$plex_plexpass" == "true" ]; then
	echo "beta enabled in config.yml... using plex beta for update..."
	iocage exec plex service plexmediaserver_plexpass stop
	# Plex is updated using PKG already, this is mostly a placeholder
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver-plexpass/
	iocage exec plex service plexmediaserver_plexpass restart
else
	echo "beta disabled in config.yml... NOT using plex beta for update..."
	iocage exec plex service plexmediaserver stop
	# Plex is updated using PKG already, this is mostly a placeholder
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver/
	iocage exec plex service plexmediaserver restart
fi





