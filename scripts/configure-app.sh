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

configure_common() {
    # Set application directory names from name variable
    APP_DIR=/opt/$APP_NAME
    APP_ETCDIR=/etc/opt/$APP_NAME
    APP_VARDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_CONFIG=$APP_ETCDIR/app.ini
}

configure_defaults() {
    # Set application group and user identification
    APP_GID=root
    APP_UID=root

    # Set application directory names from name variable
    APP_LOGDIR=/var/opt/$APP_NAME
    APP_RUNDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/app.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/sock
    UWSGI_CONF_FILES=
}

configure_opensuse() {
    # Set application group and user identification
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=

    # Set application directory names
    APP_LOGDIR=/var/opt/$APP_NAME
    APP_RUNDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
    UWSGI_CONF_FILES="\
    $UWSGI_ETCDIR/vassals/$APP_NAME.ini \
    "
}

configure_ubuntu() {
    # Set application group and user identification
    APP_GID=www-data
    APP_UID=www-data

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=/var/log/uwsgi/app
    UWSGI_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set application directory names
    APP_LOGDIR=$UWSGI_LOGDIR
    APP_RUNDIR=$UWSGI_RUNDIR

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
    UWSGI_CONF_FILES="\
    $UWSGI_ETCDIR/apps-available/$APP_NAME.ini \
    $UWSGI_ETCDIR/apps-enabled/$APP_NAME.ini \
    "
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

configure_common

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		configure_ubuntu
		;;
	    (opensuse-*)
		configure_opensuse
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
