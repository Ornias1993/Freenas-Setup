## Intro

JailMan is a collection of shell scripts designed to make it easier to install iocage Jails on FreeNAS and/or TrueNAS core.
Inspirations for this script are: Docker, FreeNAS plugins, Pentaflake's guide and "freenas-iocage-nextcloud" by danb35.
The updater is inspired by the updater designed for ZFS-Compression-Test by Ornias1993.

The goal of this project is to be able to install, update, reinstall, upgrade and delete most of your services by just running a single command.
While doing this we aim for a "docker like" scenario, where the jail is completely disposable and all configuration is saved outside of the jail.

Example: 
If something goes wrong with Jackett, you just use:
'jailman -r jackett' 


## Install
- Get into FreeNAS using the in-gui console or SSH.
Run the following commands to install jailman:
- `git clone https://github.com/Ornias1993/jailman.git`
- `cd jailman`
- `cp config.yml.example config.yml`
- edit config.yml to reflect your personal settings (optional, see "use")
- Run one of the commands under "use"

Thats all.


## Update
This script includes an autoupdate feature which checks if changes to the script has been posted to github.

## Use
Replace $jailname with the name of the jail you want to install.
For supported jails, please see this readme or config.yml.example

- First: CD into the directory you downloaded jailman into (see above)
example:
`cd /root/jailman`

- Install:
`./jailman.sh -i $jailname`
Example:
`./jailman.sh -i sonarr`

- ReInstall:
`./jailman.sh -r $jailname`
Example:
`./jailman.sh -r sonarr`

- Destroy
`./jailman.sh -d $jailname`
Example:
`./jailman.sh -d sonarr`

You can also do multiple jails in one pass:
Example:
`jailman.sh -i sonarr radarr lidarr`

This installs the jail, creates the config dataset if needed, installs all packages and sets them up for you.
Only thing you need to do is do the setup of the packages in their respective GUI.
All settings for the applications inside the jails are persistent across reinstalls, so don't worry reinstalling!

config.yml.example includes basic configuration for all jails.
Basic means: The same setup as a FreeNAS plugin would've, DHCP on bridge0.

## Currently Supported Services

### General

- organizr
- py-kms

### Downloads

- transmission
- jackett

### Media

- plex
- tautulli
- sonarr
- radarr
- lidarr

## References

- Pentaflake's guide:
https://www.ixsystems.com/community/resources/fn11-3-iocage-jails-plex-tautulli-sonarr-radarr-lidarr-jackett-transmission-organizr.58/

- "freenas-iocage-nextcloud" by danb35:
https://github.com/danb35/freenas-iocage-nextcloud

- "ZFS-Compression-Test" by Ornias1993:
https://github.com/Ornias1993/zfs-compression-test

- "py-kms" by SystemRage and others:
https://github.com/SystemRage/py-kms



### LICENCE
This work is dual licenced under GPLv2 and BSD-2 clause

## Sub-Licences
Some sub-modules available under "jails" might be licenced under a different licence.
Please be aware of this and take note of any LICENCE files signaling a differently licenced sub-module.