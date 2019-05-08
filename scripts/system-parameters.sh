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
    # Set application directory names from APP_NAME
    APP_DIR=/opt/$APP_NAME
    APP_ETCDIR=/etc/opt/$APP_NAME
    APP_VARDIR=/var/opt/$APP_NAME

    # Set uWSGI parameters
    UWSGI_BINARY_DIR=
    UWSGI_BINARY_NAME=uwsgi
    UWSGI_PLUGIN_DIR=
    UWSGI_PLUGIN_NAME=python3_plugin.so
}

configure_darwin() {
    # Set application directory names from APP_NAME
    APP_DIR=/usr/local/opt/$APP_NAME
    APP_ETCDIR=/usr/local/etc/opt/$APP_NAME
    APP_VARDIR=/usr/local/var/opt/$APP_NAME

    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www

    # Set application directory names from APP_VARDIR
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI top-level directories
    UWSGI_PREFIX=/usr/local/opt/uwsgi
    UWSGI_ETCDIR=/usr/local/etc/uwsgi
    UWSGI_LOGDIR=/usr/local/var/log
    UWSGI_RUNDIR=/usr/local/var/run

    # Set uWSGI directories from UWSGI_PREFIX
    UWSGI_BINARY_DIR=$UWSGI_PREFIX/bin
    UWSGI_PLUGIN_DIR=$UWSGI_PREFIX/lib/plugin
}

configure_debian() {
    # Set application group and user accounts
    APP_GID=www-data
    APP_UID=www-data

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=/var/log/uwsgi/app
    UWSGI_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set application directory names
    APP_LOGDIR=$UWSGI_LOGDIR
    APP_RUNDIR=$UWSGI_RUNDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI directories
    UWSGI_BINARY_DIR=/usr/bin
    UWSGI_PLUGIN_DIR=/usr/lib/uwsgi/plugins
}

configure_freebsd() {
    # Set application group and user accounts
    APP_GID=wheel
    APP_UID=root

    # Set application directory names from APP_NAME
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS=

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=
}

configure_nt() {
    # Set application group and user accounts
    APP_GID="$(id -gn)"
    APP_UID="$(id -un)"
    # Set application directory names from APP_NAME
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS="vassals"

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=
}

configure_opensuse() {
    # Set application group and user accounts
    APP_GID=nogroup
    APP_UID=nobody

    # Set application directory names from APP_NAME
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS="vassals"

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=
}

configure_sunos() {
    # Set application group and user accounts
    APP_GID=sys
    APP_UID=root

    # Set application directory names from APP_NAME
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from app directories
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS=

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=
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

    # Set additional common parameters from app directories
    APP_CONFIG=$APP_ETCDIR/app.ini
}
