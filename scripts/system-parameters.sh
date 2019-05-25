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

APP_PLUGIN=python3
APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_PIDFILE APP_PLUGIN APP_PORT APP_UID"

configure_darwin() {
    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI top-level directories
    UWSGI_OPTDIR=$UWSGI_PREFIX/opt/uwsgi

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_OPTDIR/bin
    UWSGI_PLUGIN_DIR=$UWSGI_OPTDIR/lib/plugins
}

configure_freebsd() {
    # Set app plugin
    unset APP_PLUGIN

    # Set application group and user accounts
    APP_GID=uwsgi
    APP_UID=uwsgi

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_NAME=uwsgi-3.6
}

configure_linux_debian() {
    # Set application group and user accounts
    APP_GID=www-data
    APP_UID=www-data

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI top-level directories
    UWSGI_LOGDIR=/var/log/uwsgi/app
    UWSGI_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set additional file/directory parameters
    APP_LOGDIR=$UWSGI_LOGDIR
    APP_RUNDIR=$UWSGI_RUNDIR

    # Set additional parameters from app directories
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
}

configure_linux_opensuse() {
    # Set application group and user accounts
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI configuration directories
    UWSGI_APPDIRS=vassals

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_linux_redhat() {
    # Set application group and user accounts
    APP_GID=uwsgi
    APP_UID=uwsgi

    # Set uWSGI directories
    UWSGI_APPDIRS=uwsgi.d

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc
    UWSGI_RUNDIR=/run/uwsgi

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_system_defaults() {
    # Set application directory prefix
    if [ -z "${APP_PREFIX-}" ]; then
	APP_PREFIX=
    fi

    # Set application directories from APP_NAME and APP_PREFIX
    APP_DIR=$APP_PREFIX/opt/$APP_NAME
    APP_ETCDIR=$APP_PREFIX/etc/opt/$APP_NAME

    if [ -z "${APP_VARDIR-}" ]; then
	APP_VARDIR=$APP_PREFIX/var/opt/$APP_NAME
    fi

    # Set additional file/directory parameters
    APP_CONFIG=$APP_ETCDIR/app.ini

    # Set uWSGI prefix directory
    if [ -z "${UWSGI_PREFIX-}" ]; then
	UWSGI_PREFIX=
    fi

    # Set uWSGI top-level directories

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	UWSGI_ETCDIR=$UWSGI_PREFIX/etc/uwsgi
    fi

    if [ -z "${UWSGI_LOGDIR-}" ]; then
	UWSGI_LOGDIR=$UWSGI_PREFIX/var/log
    fi

    if [ -z "${UWSGI_RUNDIR-}" ]; then
	UWSGI_RUNDIR=$UWSGI_PREFIX/var/run
    fi

    # Set uWSGI binary/plugin directories

    if [ -z "${UWSGI_BINARY_DIR-}" ]; then
	UWSGI_BINARY_DIR=${UWSGI_PREFIX:-/usr}/bin
    fi

    if [ -z "${UWSGI_PLUGIN_DIR-}" -a -n "${APP_PLUGIN-}" ]; then
	UWSGI_PLUGIN_DIR=${UWSGI_PREFIX:-/usr}/lib/uwsgi/plugins
    fi

    # Set additional file/directory parameters

    if [ -z "${APP_LOGDIR-}" ]; then
	APP_LOGDIR=$APP_VARDIR
    fi

    if [ -z "${APP_RUNDIR-}" ]; then
	APP_RUNDIR=$APP_VARDIR
    fi

    # Set uWSGI binary/plugin filenames

    if [ -z "${UWSGI_BINARY_NAME-}" ]; then
	UWSGI_BINARY_NAME=uwsgi
    fi

    if [ -z "${UWSGI_PLUGIN_NAME-}" -a -n "${APP_PLUGIN-}" ]; then
	UWSGI_PLUGIN_NAME=${APP_PLUGIN}_plugin.so
    fi

    # Set additional parameters from app directories

    if [ -z "${APP_LOGFILE-}" ]; then
	APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    fi

    if [ -z "${APP_PIDFILE-}" ]; then
	APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    fi

    if [ -z "${APP_SOCKET-}" ]; then
	APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    fi
}

configure_system() {
    eval $("$script_dir/get-os-release.sh" -X)

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(10)
			    configure_linux_debian
			    ;;
			('')
			    case "$(cat /etc/debian_version)" in
				(buster/sid)
				    configure_linux_debian
				    ;;
				(*)
				    abort_not_supported Release
				    ;;
			    esac
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ubuntu)
		    case "$VERSION_ID" in
			(18.*|19.04)
			    configure_linux_debian
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-tumbleweed)
		    case "$VERSION_ID" in
			(2019*)
			    configure_linux_opensuse
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(fedora|redhat|centos)
		    configure_linux_redhat
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    configure_darwin
	    ;;
	(FreeBSD)
	    configure_freebsd
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    configure_system_defaults
}
