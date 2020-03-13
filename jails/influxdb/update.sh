#!/usr/local/bin/bash
# This file contains the update script for influxdb

iocage exec influxdb service influxd stop
# InfluxDB is updated during PKG update, this file is mostly just a placeholder
iocage exec influxdb service influxd restart