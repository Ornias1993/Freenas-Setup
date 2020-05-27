#!/usr/local/bin/bash
# This file contains the install script for lazylibrarian

#init jail
initblueprint "$1"

# Check if dataset for completed download and it parent dataset exist, create if they do not.
createmount "$1" "${global_dataset_downloads}"
createmount "$1" "${global_dataset_downloads}"/LazyLibrarian /mnt/Complete

# Check if dataset for media library and the dataset for books, comics and magazines exist, create if they do not.
createmount "$1" "${global_dataset_media}"
createmount "$1" "${global_dataset_media}"/audiobooks /media/audiobooks
createmount "$1" "${global_dataset_media}"/books /media/books
createmount "$1" "${global_dataset_media}"/comics /media/comics
createmount "$1" "${global_dataset_media}"/magazines /media/magazines

iocage exec "$1" "git clone https://gitlab.com/LazyLibrarian/LazyLibrarian.git /usr/local/share/lazylibrarian"
iocage exec "$1" "git clone git://github.com/urllib3/urllib3.git /urllib3"
iocage exec "$1" "python /urllib3/setup.py install"
iocage exec "$1" "rm -r /urllib3"
iocage exec "$1" "pw user add lazylibrarian -c lazylibrarian -u 111 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$1" chown -R lazylibrarian:lazylibrarian /usr/local/share/lazylibrarian /config
iocage exec "$1" mkdir /usr/local/etc/rc.d
cp "${includes_dir}/lazylibrarian.rc" "${jail_root}/usr/local/etc/rc.d/lazylibrarian"
iocage exec "$1" chmod u+x /usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" sysrc "lazylibrarian_enable=YES"
iocage exec "$1" sed -i '' -e 's|/var/run/lazylibrarian/lazylibrarian.pid|/config/lazylibrarian.pid|g' /usr/local/etc/rc.d/lazylibrarian
iocage exec "$1" "pkg update && pkg upgrade -y"
iocage exec "$1" service lazylibrarian start

exitblueprint "$1"
