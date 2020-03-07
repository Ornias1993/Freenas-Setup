#!/usr/local/bin/bash
# This file contains the install script for Organizr

iocage exec organizr sed -i '' -e 's?listen = 127.0.0.1:9000?listen = /var/run/php-fpm.sock?g' /usr/local/etc/php-fpm.d/www.conf
iocage exec organizr sed -i '' -e 's/;listen.owner = www/listen.owner = www/g' /usr/local/etc/php-fpm.d/www.conf
iocage exec organizr sed -i '' -e 's/;listen.group = www/listen.group = www/g' /usr/local/etc/php-fpm.d/www.conf
iocage exec organizr sed -i '' -e 's/;listen.mode = 0660/listen.mode = 0600/g' /usr/local/etc/php-fpm.d/www.conf
iocage exec organizr cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini
mv /mnt/${global_dataset_iocage}/jails/organizr/root/usr/local/etc/nginx/nginx.conf /mnt/${global_dataset_iocage}/jails/organizr/root/usr/local/etc/nginx/nginx.conf.bak
cp ${SCRIPT_DIR}/jails/organizr/includes/nginx.conf /mnt/${global_dataset_iocage}/jails/organizr/root/usr/local/etc/nginx/nginx.conf
cp -Rf ${SCRIPT_DIR}/jails/organizr/includes/custom /mnt/${global_dataset_iocage}/jails/organizr/root/usr/local/etc/nginx/custom

if [ ! -d "/mnt/${global_dataset_config}/organizr/cert" ]; then
	echo "cert folder not existing... creating..."
	iocage exec organizr mkdir /config/cert
fi

if [ -f "/mnt/${global_dataset_config}/organizr/cert/Organizr-Cert.crt" ]; then
    echo "certificate exist... Skipping cert generation"
else
	"No ssl certificate present, generating self signed certificate"
	openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" -keyout /mnt/${global_dataset_config}/organizr/cert/Organizr-Cert.key -out /mnt/${global_dataset_config}/organizr/cert/Organizr-Cert.crt
fi

iocage exec organizr git clone https://github.com/causefx/Organizr.git /usr/local/www/Organizr
iocage exec organizr chown -R www:www /usr/local/www /config /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/custom
iocage exec organizr ln -s /config/config.php /usr/local/www/Organizr/api/config/config.php
iocage exec organizr sysrc nginx_enable=YES
iocage exec organizr sysrc php_fpm_enable=YES
iocage exec organizr service nginx start
iocage exec organizr service php-fpm start
