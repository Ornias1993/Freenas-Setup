iocage exec test10 service sonarr stop

iocage exec test10 chown -R sonarr:sonarr /usr/local/share/NzbDrone /config
#TODO insert code to update sonarr itself here
cp ${SCRIPT_DIR}/jails/test10/includes/sonarr.rc /mnt/${global_dataset_iocage}/jails/test10/root/usr/local/etc/rc.d/sonarr
iocage exec test10 chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec test10 service sonarr restart