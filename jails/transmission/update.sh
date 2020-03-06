#!/usr/local/bin/bash
# This file contains the update script for transmission

iocage exec transmission service transmission stop
# Transmision is updated during PKG update, this file is mostly just a placeholder
iocage exec transmission chown -R transmission:transmission /config
iocage exec transmission service transmission restart