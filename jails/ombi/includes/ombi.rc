#!/bin/sh
#
# $FreeBSD$
#
# PROVIDE: ombi
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# ombi_enable (bool): Set to NO by default.
# Set it to YES to enable it.
# ombi_user: The user account ombi daemon runs as what
# you want it to be. It uses 'ombi' user by
# default. Do not sets it as empty or it will run
# as root.
# ombi_group: The group account ombi daemon runs as what
# you want it to be. It uses 'ombi' group by
# default. Do not sets it as empty or it will run
# as wheel.
# ombi_data_dir: Directory where ombi configuration
# data is stored.
# Default: /usr/local/share/ombi

. /etc/rc.subr

name=ombi
rcvar=ombi_enable
load_rc_config ${name}

: ${ombi_enable:=NO}
: ${ombi_user:=ombi}
: ${ombi_group:=ombi}
: ${ombi_data_dir:="/config"}

procname="/usr/local/bin/mono"
command="/usr/sbin/daemon"
command_args="-f ${procname} /usr/local/share/ombi/Ombi.exe"

start_precmd=ombi_precmd
ombi_precmd() {
if [ ! -d ${ombi_data_dir} ];
then install -d -o ${ombi_user} -g ${ombi_group} ${ombi_data_dir}
fi
export XDG_CONFIG_HOME=${ombi_data_dir}
}

run_rc_command "$1"