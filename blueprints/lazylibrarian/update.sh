#!/usr/local/bin/bash
# This file contains the update script for lazylibrarian

iocage exec "$1" service lazylibrarian stop
#TODO insert code to update lazylibrarian itself here
iocage exec "$1" chown -R lazylibrarian:lazylibrarian /usr/local/share/lazylibrarian /config
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/blueprints/lazylibrarian/includes/lazylibrarian.rc /mnt/"${global_dataset_iocage}"/jails/"$1"/root/usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" chmod u+x /usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" service lazylibrarian restart
