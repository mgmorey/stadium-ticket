# -*- Mode: Shell-script -*-

# system-parameters.sh: application configuration parameters
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

configure_common() {
    # Set uWSGI parameters
    UWSGI_BINARY_NAME=uwsgi
    UWSGI_PLUGIN_NAME=python3_plugin.so

    # Set uWSGI variables
    UWSGI_VARS="APP_DIR APP_GID APP_LOGFILE APP_NAME APP_PIDFILE APP_PORT \
APP_RUNDIR APP_UID APP_VARDIR"
}

configure_darwin() {
    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI configuration directories
    UWSGI_APPDIRS=""

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI directories
    UWSGI_ETCDIR=$UWSGI_PREFIX/etc/uwsgi
    UWSGI_LOGDIR=$UWSGI_PREFIX/var/log
    UWSGI_OPTDIR=$UWSGI_PREFIX/opt/uwsgi
    UWSGI_RUNDIR=$UWSGI_PREFIX/var/run

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_OPTDIR/bin
    UWSGI_PLUGIN_DIR=$UWSGI_OPTDIR/lib/plugin
}

configure_debian() {
    # Set application group and user accounts
    APP_GID=www-data
    APP_UID=www-data

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI top-level directories
    UWSGI_PREFIX=/usr
    UWSGI_LOGDIR=/var/log/uwsgi/app
    UWSGI_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_PREFIX/bin
    UWSGI_PLUGIN_DIR=$UWSGI_PREFIX/lib/uwsgi/plugins

    # Set additional application directories
    APP_LOGDIR=$UWSGI_LOGDIR

    # Set additional parameters from app directories
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
}

configure_freebsd() {
    # Set application group and user accounts
    APP_GID=wheel
    APP_UID=root

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"
}

configure_opensuse() {
    # Set application group and user accounts
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI directories
    UWSGI_APPDIRS="vassals"
    UWSGI_PLUGIN_DIR=.
}

configure_sunos() {
    # Set application group and user accounts
    APP_GID=sys
    APP_UID=root

    # Set additional application directories
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR
}

configure_system_defaults() {
    # Set application directory prefix
    if [ -z "${APP_PREFIX-}" ]; then
	APP_PREFIX=""
    fi

    # Set application directories from APP_NAME and APP_PREFIX
    APP_DIR=$APP_PREFIX/opt/$APP_NAME
    APP_ETCDIR=$APP_PREFIX/etc/opt/$APP_NAME
    APP_VARDIR=$APP_PREFIX/var/opt/$APP_NAME

    # Set additional file/directory parameters
    APP_CONFIG=$APP_ETCDIR/app.ini

    if [ -z "${APP_LOGDIR-}" ]; then
	APP_LOGDIR=$APP_VARDIR
    fi

    if [ -z "${APP_RUNDIR-}" ]; then
	APP_RUNDIR=$APP_VARDIR
    fi

    if [ -z "${APP_LOGFILE-}" ]; then
        APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    fi

    if [ -z "${APP_PIDFILE-}" ]; then
	APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    fi

    if [ -z "${APP_SOCKET-}" ]; then
        APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    fi

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	UWSGI_ETCDIR=/etc/uwsgi
    fi
}

configure_system() {
    eval $("$script_dir/get-os-release.sh" -X)

    configure_common

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(10)
			    configure_debian
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ubuntu)
		    case "$VERSION_ID" in
			(18.*|19.04)
			    configure_debian
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-tumbleweed)
		    case "$VERSION_ID" in
			(2019*)
			    configure_opensuse
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    configure_darwin
	    ;;
	# (FreeBSD)
	#	configure_freebsd
	#	;;
	# (SunOS)
	#	configure_sunos
	#	;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    configure_system_defaults
}
