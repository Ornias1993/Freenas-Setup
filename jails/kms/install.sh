#!/usr/local/bin/bash
# This file contains the install script for KMS


iocage exec kms svn checkout https://github.com/SystemRage/py-kms/trunk/py-kms /usr/local/share/py-kms
iocage exec kms "pw user add kms -c kms -u 666 -d /nonexistent -s /usr/bin/nologin"
iocage exec kms chown -R kms:kms /usr/local/share/py-kms /config
iocage exec kms mkdir /usr/local/etc/rc.d
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/jails/kms/includes/py_kms.rc /mnt/"${global_dataset_iocage}"/jails/kms/root/usr/local/etc/rc.d/py_kms
iocage exec kms chmod u+x /usr/local/etc/rc.d/py_kms
iocage exec kms sysrc "py_kms_enable=YES"
iocage exec kms service py_kms start