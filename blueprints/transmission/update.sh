#!/usr/local/bin/bash
# This file contains the update script for transmission

initjail "$1"

iocage exec "$1" service transmission stop
# Transmision is updated during PKG update, this file is mostly just a placeholder
iocage exec "$1" chown -R transmission:transmission /config
iocage exec "$1" service transmission restart