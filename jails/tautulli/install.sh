#!/usr/local/bin/bash
# This file contains the install script for Tautulli


iocage exec tautulli git clone https://github.com/Tautulli/Tautulli.git /usr/local/share/Tautulli
iocage exec tautulli "pw user add tautulli -c tautulli -u 109 -d /nonexistent -s /usr/bin/nologin"
iocage exec tautulli chown -R tautulli:tautulli /usr/local/share/Tautulli /config
iocage exec tautulli cp /usr/local/share/Tautulli/init-scripts/init.freenas /usr/local/etc/rc.d/tautulli
iocage exec tautulli chmod u+x /usr/local/etc/rc.d/tautulli
iocage exec tautulli sysrc "tautulli_enable=YES"
iocage exec tautulli sysrc "tautulli_flags=--datadir /config"
iocage exec tautulli service tautulli start