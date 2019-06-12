# -*- Mode: Shell-script -*-

# system-parameters.sh: system configuration parameters
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_PIDFILE APP_PLUGIN APP_PORT APP_UID \
APP_VARDIR"

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

configure_bsd() {
    # Set ps command format and command column
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_darwin() {
    configure_darwin_common

    if [ "${UWSGI_IS_SOURCE_ONLY-false}" = true ]; then
	configure_darwin_source
    else
	configure_darwin_native
    fi
}

configure_darwin_common() {
    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI binary/plugin filenames
    UWSGI_BINARY_NAME=uwsgi
    UWSGI_PLUGIN_NAME=python3_plugin.so
}

configure_darwin_native() {
    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=$UWSGI_PREFIX/etc/uwsgi
    UWSGI_OPTDIR=$UWSGI_PREFIX/opt/uwsgi

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_OPTDIR/bin
    UWSGI_PLUGIN_DIR=$UWSGI_OPTDIR/libexec/uwsgi

    # Set uWSGI log filename
    UWSGI_LOGFILE=$UWSGI_PREFIX/var/log/uwsgi.log
}

configure_darwin_source() {
    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_PREFIX/bin
    UWSGI_PLUGIN_DIR=$UWSGI_PREFIX/lib/uwsgi/plugins
}

configure_freebsd() {
    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI binary file
    UWSGI_BINARY_NAME=uwsgi-3.6

    # Set uWSGI run service
    UWSGI_RUN_AS_SERVICE=false
}

configure_linux() {
    # Set ps command format and command column
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_linux_debian_common() {
    # Set application group and user accounts
    APP_GID=www-data
    APP_UID=www-data
}

configure_linux_debian_native() {
    configure_linux_debian_common

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set additional file/directory parameters
    APP_LOGDIR=/var/log/uwsgi/app
    APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set additional parameters from app directories
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/socket
}

configure_linux_debian_source() {
    configure_linux_debian_common

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI binary/plugin filenames
    UWSGI_BINARY_NAME=uwsgi
    UWSGI_PLUGIN_NAME=python3_plugin.so

    # Set uWSGI run service
    UWSGI_RUN_AS_SERVICE=false
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
    # Set uWSGI configuration directories
    UWSGI_APPDIRS=uwsgi.d

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_openindiana() {
    # Set application group and user accounts
    APP_GID=webserverd
    APP_UID=webserverd

    # Set application directory prefix
    APP_PREFIX=

    # Set uWSGI prefix directory
    UWSGI_PREFIX=

    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=$UWSGI_PREFIX/opt/etc/uwsgi
    UWSGI_OPTDIR=$UWSGI_PREFIX/opt/uwsgi

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_OPTDIR/bin
    UWSGI_PLUGIN_DIR=$UWSGI_OPTDIR/libexec/uwsgi

    # Set uWSGI binary/plugin filenames
    UWSGI_BINARY_NAME=uwsgi
    UWSGI_PLUGIN_NAME=python3_plugin.so

    # Set uWSGI log filename
    UWSGI_LOGFILE=$UWSGI_PREFIX/var/opt/uwsgi.log
}

configure_sunos() {
    # Set ps command format and command column
    PS_COLUMN=6
    PS_FORMAT=pid,ppid,user,tty,stime,args
}

configure_system_defaults() {
    # Set application group and user accounts

    if [ -z "${APP_GID-}" ]; then
	APP_GID=uwsgi
    fi

    if [ -z "${APP_UID-}" ]; then
	APP_UID=uwsgi
    fi

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

    # Set uWSGI top-level directories

    # Set uWSGI directory prefix
    if [ -z "${UWSGI_PREFIX-}" ]; then
	UWSGI_PREFIX=
    fi

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	UWSGI_ETCDIR=${UWSGI_PREFIX-}/etc/uwsgi
    fi

    # Set uWSGI binary/plugin directories

    if [ -z "${UWSGI_BINARY_DIR-}" ]; then
	UWSGI_BINARY_DIR=${UWSGI_PREFIX:-/usr}/bin
    fi

    if [ -z "${UWSGI_BINARY_NAME-}" ]; then
	UWSGI_BINARY_NAME=uwsgi
    fi

    if [ -z "${UWSGI_PLUGIN_DIR-}" ]; then
	UWSGI_PLUGIN_DIR=${UWSGI_PREFIX:-/usr}/lib/uwsgi/plugins
    fi

    if [ -z "${UWSGI_PLUGIN_NAME-}" -a -d $UWSGI_PLUGIN_DIR ]; then
	UWSGI_PLUGIN_NAME=$(find_uwsgi_plugin || true)
    fi

    if [ -z "${UWSGI_IS_SOURCE_ONLY-}" ]; then
	UWSGI_IS_SOURCE_ONLY=false
    fi

    if [ -z "${UWSGI_RUN_AS_SERVICE-}" ]; then
	UWSGI_RUN_AS_SERVICE=true
    fi

    # Set app plugin from uWSGI plugin filename
    if [ -z "${APP_PLUGIN-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	APP_PLUGIN=${UWSGI_PLUGIN_NAME%_plugin.so}
    fi

    # Set additional app directory parameters

    if [ -z "${APP_LOGDIR-}" ]; then
	APP_LOGDIR=$APP_VARDIR
    fi

    if [ -z "${APP_RUNDIR-}" ]; then
	APP_RUNDIR=$APP_VARDIR
    fi

    # Set additional file parameters from app directories

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
	    configure_linux

	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(9)
			    # Build uWSGI from source
			    UWSGI_IS_SOURCE_ONLY=true
			    configure_linux_debian_source
			    ;;
			(10)
			    configure_linux_debian_native
			    ;;
			('')
			    case "$(cat /etc/debian_version)" in
				(buster/sid)
				    configure_linux_debian_native
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
			    configure_linux_debian_native
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-leap)
		    case "$VERSION_ID" in
			(15.0|15.1)
			    configure_linux_opensuse
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
	    # Build uWSGI from source
	    UWSGI_IS_SOURCE_ONLY=true
	    configure_bsd
	    configure_darwin
	    ;;
	(FreeBSD)
	    configure_bsd
	    configure_freebsd
	    ;;
	(SunOS)
	    configure_sunos

	    case $ID in
		# (openindiana)
		#     # Build uWSGI from source
		#     UWSGI_IS_SOURCE_ONLY=true
		#     configure_openindiana
		#     ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    configure_system_defaults
}

find_uwsgi_plugin() (
    if [ -z "$UWSGI_PLUGIN_DIR" ]; then
	return 1
    elif [ ! -d $UWSGI_PLUGIN_DIR ]; then
	return 1
    elif [ ! cd $UWSGI_PLUGIN_DIR ]; then
	return 1
    fi

    versions=$(printf "%s\n" $PYTHON_VERSIONS | tr -d .)
    plugins=$(printf "python%s_plugin.so\n" $versions)
    ls $plugins 2>/dev/null | sort -Vr | head -n 1
)

validate_parameters_postinstallation() {
    if [ ! -d $APP_ETCDIR ]; then
	abort "%s: %s: No such configuration directory\n" "$0" "$APP_ETCDIR"
    elif [ ! -r $APP_CONFIG ]; then
	abort "%s: %s: No read permission\n" "$0" "$APP_CONFIG"
    elif [ ! -e $APP_CONFIG ]; then
	abort "%s: %s: No such configuration file\n" "$0" "$APP_CONFIG"
    elif [ ! -d $APP_DIR ]; then
	abort "%s: %s: No such app directory\n" "$0" "$APP_DIR"
    elif [ ! -d $APP_VARDIR ]; then
	abort "%s: %s: No such var directory\n" "$0" "$APP_VARDIR"
    elif [ ! -d $APP_LOGDIR ]; then
	abort "%s: %s: No such log directory\n" "$0" "$APP_LOGDIR"
    elif [ ! -d $APP_RUNDIR ]; then
	abort "%s: %s: No such run directory\n" "$0" "$APP_RUNDIR"
    elif [ -e $APP_LOGFILE -a ! -w $APP_LOGFILE ]; then
	abort_insufficient_permissions "$APP_LOGFILE"
    elif [ -e $APP_PIDFILE -a ! -w $APP_PIDFILE ]; then
	abort_insufficient_permissions "$APP_PIDFILE"
    fi
}

validate_parameters_preinstallation() {
    binary=$UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME

    if [ -n "${UWSGI_PLUGIN_DIR-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	plugin=$UWSGI_PLUGIN_DIR/$UWSGI_PLUGIN_NAME
    fi

    if [ ! -d $UWSGI_BINARY_DIR ]; then
	abort "%s: %s: No such binary directory\n" "$0" "$UWSGI_BINARY_DIR"
    elif [ ! -e $binary ]; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    elif [ ! -x $binary ]; then
	abort "%s: %s: No execute permission\n" "$0" "$binary"
    elif ! $binary --version >/dev/null 2>&1; then
	abort "%s: %s: Unable to query version\n" "$0" "$binary"
    elif [ -n "${plugin-}" ]; then
	if [ ! -d $UWSGI_PLUGIN_DIR ]; then
	    abort "%s: %s: No such plugin directory\n" "$0" "$UWSGI_PLUGIN_DIR"
	elif [ ! -e $plugin ]; then
	    abort "%s: %s: No such plugin file\n" "$0" "$plugin"
	elif [ ! -r $plugin ]; then
	    abort "%s: %s: No read permission\n" "$0" "$plugin"
	fi
    fi
}
