#!/usr/local/bin/bash
# This file contains the install script for plex

iocage exec plex mkdir -p /usr/local/etc/pkg/repos
iocage exec plex mkdir -p /mnt/media
iocage exec plex mkdir -p /mnt/media/movies
iocage exec plex mkdir -p /mnt/media/music
iocage exec plex mkdir -p /mnt/media/shows

# Change to to more frequent FreeBSD repo to stay up-to-date with plex more.
cp ${SCRIPT_DIR}/jails/plex/includes/FreeBSD.conf /mnt/${global_dataset_iocage}/jails/plex/root/usr/local/etc/pkg/repos/FreeBSD.conf


# Check if datasets for media librarys exist, create them if they do not.
if [ ! -d "/mnt/${global_dataset_media}" ]; then
	echo "Media dataset does not exist... Creating... ${global_dataset_media}"
	zfs create ${global_dataset_media}
fi

iocage fstab -a plex /mnt/${global_dataset_media} /mnt/media nullfs rw 0 0

if [ ! -d "/mnt/${global_dataset_media}/shows" ]; then
	echo "TV Shows dataset does not exist... Creating... ${global_dataset_media}/shows"
	zfs create ${global_dataset_media}/shows
fi

iocage fstab -a plex /mnt/${global_dataset_media}/shows /mnt/media/shows nullfs rw 0 0

if [ ! -d "/mnt/${global_dataset_media}/music" ]; then
	echo "music dataset does not exist... Creating... ${global_dataset_media}/music"
	zfs create ${global_dataset_media}/music
fi

iocage fstab -a plex /mnt/${global_dataset_media}/music /mnt/media/music nullfs rw 0 0

if [ ! -d "/mnt/${global_dataset_media}/movies" ]; then
	echo "movies dataset does not exist... Creating... ${global_dataset_media}/movies"
	zfs create ${global_dataset_media}/movies
fi

iocage fstab -a plex /mnt/${global_dataset_media}/movies /mnt/media/movies nullfs rw 0 0


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