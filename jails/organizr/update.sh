iocage exec organizr service nginx stop
iocage exec organizr service php-fpm stop
iocage update organizr
iocage exec organizr "pkg update && pkg upgrade -y"
cp ../includes/organizr-conf/nginx.conf /mnt/tank/iocage/jails/organizr/root/usr/local/etc/nginx/nginx.conf
cp ../includes/organizr-conf/custom/*.* /mnt/tank/iocage/jails/organizr/root/usr/local/etc/nginx/custom/
iocage exec organizr "cd /usr/local/www/Organizr && git pull"
iocage exec organizr chown -R www:www /usr/local/www /config /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/custom
iocage exec organizr service nginx start
iocage exec organizr service php-fpm start