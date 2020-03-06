#!/usr/local/bin/bash
# This file contains the update script for Plex

# Run different update procedures depending on Plex vs Plexpass
if [ "$plex_plexpass" == "true" ]; then
	echo "plexpass enabled in config.yml... using plexpass for update..."
	iocage exec plex service plexmediaserver_plexpass stop
	# Plex is updated using PKG already, this is mostly a placeholder
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver-plexpass/
	iocage exec plex service plexmediaserver_plexpass restart
else
	echo "plexpass disabled in config.yml... NOT using plexpass for update..."
	iocage exec plex service plexmediaserver stop
	# Plex is updated using PKG already, this is mostly a placeholder
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver/
	iocage exec plex service plexmediaserver restart
fi





