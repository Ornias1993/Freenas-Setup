#!/usr/local/bin/bash
# This file contains the update script for Organizr


iocage exec organizr service nginx stop
iocage exec organizr service php-fpm stop
# TODO setup cli update for Organizr here.
cp ${SCRIPT_DIR}/jails/organizr/includes/nginx.conf /mnt/${global_dataset_iocage}/jails/organizr/root/usr/local/etc/nginx/nginx.conf
iocage exec organizr "cd /usr/local/www/Organizr && git pull"
iocage exec organizr chown -R www:www /usr/local/www /config /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/custom
iocage exec organizr service nginx start
iocage exec organizr service php-fpm start