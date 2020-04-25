#!/usr/local/bin/bash
# This file contains the update script for KMS

iocage exec kms service py_kms stop
iocage exec kms svn checkout https://github.com/SystemRage/py-kms/trunk/py-kms /usr/local/share/py-kms
iocage exec kms chown -R kms:kms /usr/local/share/py-kms /config
# shellcheck disable=SC2154
cp "${SCRIPT_DIR}"/jails/kms/includes/py_kms.rc /mnt/"${global_dataset_iocage}"/jails/kms/root/usr/local/etc/rc.d/py_kms
iocage exec kms chmod u+x /usr/local/etc/rc.d/py_kms
iocage exec kms service py_kms start