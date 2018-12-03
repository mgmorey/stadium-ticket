# -*- Mode: Shell-script -*-

# configure-app.sh: configure uWSGI application
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Application-specific parameters
APP_NAME=stadium-ticket
APP_PORT=5000

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
APP_ETCDIR=/etc/opt/$APP_NAME
APP_LOGDIR=/var/opt/$APP_NAME
APP_RUNDIR=/var/opt/$APP_NAME
APP_VARDIR=/var/opt/$APP_NAME

# Set common directory names
UWSGI_ETCDIR=/etc/uwsgi

# Set additional variables using directory variables
APP_CONFIG=$APP_ETCDIR/app.ini
APP_LOGFILE=$APP_LOGDIR/app.log

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		APP_GID=www-data
		APP_UID=www-data

		APP_CONF_AVAIL=$UWSGI_ETCDIR/apps-available/$APP_NAME.ini
		APP_CONF_ENABLED=$UWSGI_ETCDIR/apps-enabled/$APP_NAME.ini
		APP_LOGDIR=/var/log/uwsgi/app
		APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME

		APP_CONF_FILES="$APP_CONFIG $APP_CONF_AVAIL $APP_CONF_ENABLED"
		APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
		APP_PIDFILE=$APP_RUNDIR/pid
		APP_SOCKET=$APP_RUNDIR/socket
		;;
	    (opensuse-*)
		APP_GID=nogroup
		APP_UID=nobody

		APP_CONF_VASSAL=$UWSGI_ETCDIR/vassals/$APP_NAME.ini

		APP_CONF_FILES="$APP_CONFIG $APP_CONF_VASSAL"
		APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
		APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
