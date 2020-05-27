#!/usr/local/bin/bash
# This file contains the update script for lazylibrarian

#init jail
initblueprint "$1"

iocage exec "$1" service lazylibrarian stop
iocage exec "$1" git -C /usr/local/share/lazylibrarian pull
iocage exec "$1" "python /urllib3/setup.py install"
iocage exec "$1" chown -R lazylibrarian:lazylibrarian /usr/local/share/lazylibrarian /config
cp "${SCRIPT_DIR}"/blueprints/lazylibrarian/includes/lazylibrarian.rc /mnt/"${global_dataset_iocage}"/jails/"$1"/root/usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" chmod u+x /usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" service lazylibrarian restart
