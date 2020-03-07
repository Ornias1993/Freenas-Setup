#!/usr/local/bin/bash
# This file contains the install script for plex

iocage exec plex mkdir -p /usr/local/etc/pkg/repos


# Change to to more frequent FreeBSD repo to stay up-to-date with plex more.
cp ${SCRIPT_DIR}/jails/plex/includes/FreeBSD.conf /mnt/${global_dataset_iocage}/jails/plex/root/usr/local/etc/pkg/repos/FreeBSD.conf


# Check if datasets for media librarys exist, create them if they do not.
createmount plex ${global_dataset_media} /mnt/media
createmount plex ${global_dataset_media}/movies /mnt/media/movies
createmount plex ${global_dataset_media}/music /mnt/media/music
createmount plex ${global_dataset_media}/shows /mnt/media/shows


iocage exec plex chown -R plex:plex /config

# Force update pkg to get latest plex version
iocage exec plex pkg update
iocage exec plex pkg upgrade -y

# Run different install procedures depending on Plex vs Plexpass
if [ "$plex_plexpass" == "true" ]; then
	echo "plexpass enabled in config.yml... using plexpass for install"
	iocage exec plex sysrc "plexmediaserver_plexpass_enable=YES"
	iocage exec plex sysrc plexmediaserver_plexpass_support_path="/config"
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver-plexpass/
	iocage exec plex service plexmediaserver_plexpass restart
else
	echo "plexpass disabled in config.yml... NOT using plexpass for install"
	iocage exec plex sysrc "plexmediaserver_enable=YES"
	iocage exec plex sysrc plexmediaserver_support_path="/config"
	iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver/
	iocage exec plex service plexmediaserver restart
fi

echo "Finished installing plex"