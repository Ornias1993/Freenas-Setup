#!/usr/local/bin/bash
# This file contains the update script for Tautulli

iocage exec tautulli service tautulli stop
# Tautulli is updated through pkg, this is mostly just a placeholder
iocage exec tautulli chown -R tautulli:tautulli /usr/local/share/Tautulli /config
iocage exec tautulli cp /usr/local/share/Tautulli/init-scripts/init.freenas /usr/local/etc/rc.d/tautulli
iocage exec tautulli chmod u+x /usr/local/etc/rc.d/tautulli
iocage exec tautulli service tautulli restart