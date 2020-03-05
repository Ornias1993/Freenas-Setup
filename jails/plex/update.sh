iocage exec plex service plexmediaserver_plexpass stop
iocage update plex
iocage exec plex "pkg update && pkg upgrade -y"
iocage exec plex chown -R plex:plex /usr/local/share/plexmediaserver-plexpass/
iocage exec plex service plexmediaserver_plexpass restart
sleep 10s
iocage exec plex service plexmediaserver_plexpass start
echo "Finished updating plex"