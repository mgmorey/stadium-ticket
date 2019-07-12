# -*- Mode: Shell-script -*-

# system-parameters.sh: system configuration functions and parameters
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

APPLE_URL=http://www.apple.com/DTDs/PropertyList-1.0.dtd
AWK_FORMAT='NR == 1 || $%d == binary {print $0}\n'
PLUGIN_FORMAT="python%s_plugin.so\n"

UWSGI_BRANCH=uwsgi-2.0
UWSGI_URL=https://github.com/unbit/uwsgi.git

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

awk_uwsgi() {
    awk "$(printf "$AWK_FORMAT" $PS_COLUMN)" binary="$1"
}

configure_bsd() {
    # Set ps command format and command column
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_darwin() {
    configure_darwin_common

    if [ "${UWSGI_IS_PACKAGED-true}" = true ]; then
	configure_darwin_native
    else
	configure_darwin_source
    fi
}

configure_darwin_common() {
    # Set application group and user accounts
    APP_GID=_www
    APP_UID=_www
}

configure_darwin_native() {
    # Set uWSGI configuration directories
    UWSGI_APPDIRS="apps-available apps-enabled"

    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=$UWSGI_PREFIX/etc/uwsgi
    UWSGI_OPTDIR=$UWSGI_PREFIX/opt/uwsgi

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_OPTDIR/bin
    UWSGI_PLUGIN_DIR=$UWSGI_OPTDIR/libexec/uwsgi

    # Set other uWSGI parameters
    UWSGI_LOGFILE=$UWSGI_PREFIX/var/log/uwsgi.log
}

configure_darwin_source() {
    UWSGI_RUN_AS_SERVICE=true
    configure_source_defaults
}

configure_freebsd_11() {
    configure_freebsd_common
}

configure_freebsd_12() {
    configure_freebsd_common
}

configure_freebsd_common() {
    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set uWSGI binary file
    UWSGI_BINARY_NAME=uwsgi-3.6

    # Set other uWSGI parameters
    UWSGI_HAS_PLUGIN=false
    UWSGI_RUN_AS_SERVICE=false
}

configure_linux() {
    # Set ps command format and command column
    PS_COLUMN=10
    PS_FORMAT=pid,ppid,user,tt,lstart,command
}

configure_linux_debian() {
    configure_linux_debian_common

    if [ "${UWSGI_IS_PACKAGED-true}" = true ]; then
	configure_linux_debian_native
    else
	configure_source_defaults
    fi
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
    if [ "${UWSGI_IS_PACKAGED-true}" = true ]; then
	configure_linux_redhat_native
    else
	configure_linux_redhat_source
    fi
}

configure_linux_redhat_native() {
    # Set uWSGI configuration directories
    UWSGI_APPDIRS=uwsgi.d

    # Set uWSGI top-level directories
    UWSGI_ETCDIR=/etc

    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=/usr/sbin
    UWSGI_PLUGIN_DIR=/usr/lib64/uwsgi
}

configure_linux_redhat_source() {
    # Set application group and user accounts
    APP_GID=nobody
    APP_UID=nobody

    configure_source_defaults
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

    # Set other uWSGI parameters
    UWSGI_LOGFILE=$UWSGI_PREFIX/var/opt/uwsgi.log
}

configure_source_defaults() {
    # Set application directory prefix
    APP_PREFIX=/usr/local

    # Set uWSGI prefix directory
    UWSGI_PREFIX=/usr/local

    # Set other uWSGI parameters
    if [ -z "${UWSGI_RUN_AS_SERVICE-}" ]; then
	UWSGI_RUN_AS_SERVICE=false
    fi
}

configure_sunos() {
    # Set ps command format and command column
    PS_COLUMN=6
    PS_FORMAT=pid,ppid,user,tty,stime,args
}

configure_system() {
    configure_system_baseline
    configure_system_defaults
}

configure_system_baseline() {
    eval $("$script_dir/get-os-release.sh" -X)

    case "$kernel_name" in
	(Linux)
	    configure_linux

	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(9)
			    UWSGI_IS_PACKAGED=false
			    ;;
			(10)
			    UWSGI_IS_PACKAGED=true
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac

		    configure_linux_debian
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
		(fedora)
		    configure_linux_redhat_native
		    ;;
		(redhat|centos)
		    case "$VERSION_ID" in
			(7)
			    UWSGI_IS_PACKAGED=false
			    ;;
			(8)
			    UWSGI_IS_PACKAGED=true
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac

		    configure_linux_redhat
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    # Build uWSGI from source
	    UWSGI_IS_PACKAGED=false
	    configure_bsd
	    configure_darwin
	    ;;
	(FreeBSD)
	    configure_bsd

	    case "$VERSION_ID" in
		(11.*)
		    configure_freebsd_11
		    ;;
		(12.*)
		    configure_freebsd_12
		    ;;
	    esac
	    ;;
	(SunOS)
	    configure_sunos

	    case $ID in
		# (openindiana)
		#     # Build uWSGI from source
		#     UWSGI_IS_PACKAGED=false
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

    # Set application directories from APP_NAME and APP_PREFIX
    APP_DIR=${APP_PREFIX-}/opt/$APP_NAME
    APP_ETCDIR=${APP_PREFIX-}/etc/opt/$APP_NAME

    if [ -z "${APP_VARDIR-}" ]; then
	APP_VARDIR=${APP_PREFIX-}/var/opt/$APP_NAME
    fi

    # Set additional app file and directory parameters

    APP_CONFIG=$APP_ETCDIR/app.ini

    if [ -z "${APP_LOGDIR-}" ]; then
	APP_LOGDIR=$APP_VARDIR
    fi

    if [ -z "${APP_RUNDIR-}" ]; then
	APP_RUNDIR=$APP_VARDIR
    fi

    # Set application group and user accounts

    if [ -z "${APP_GID-}" ]; then
	APP_GID=uwsgi
    fi

    if [ -z "${APP_UID-}" ]; then
	APP_UID=uwsgi
    fi

    # Set uWSGI-related parameters

    if [ -z "${UWSGI_IS_PACKAGED-}" ]; then
	UWSGI_IS_PACKAGED=true
    fi
}

configure_system_defaults() {
    # Set uWSGI directory prefix
    if [ -z "${UWSGI_PREFIX-}" ]; then
	UWSGI_PREFIX=
    fi

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	UWSGI_ETCDIR=${UWSGI_PREFIX-}/etc/uwsgi
    fi

    # Set uWSGI-related parameters

    if [ -z "${UWSGI_HAS_PLUGIN-}" ]; then
	UWSGI_HAS_PLUGIN=true
    fi

    if [ -z "${UWSGI_RUN_AS_SERVICE-}" ]; then
	if [ "${UWSGI_IS_PACKAGED-true}" = true ]; then
	    UWSGI_RUN_AS_SERVICE=true
	else
	    UWSGI_RUN_AS_SERVICE=false
	fi
    fi

    if [ -z "${UWSGI_BINARY_DIR-}" ]; then
	UWSGI_BINARY_DIR=${UWSGI_PREFIX:-/usr}/bin
    fi

    if [ -z "${UWSGI_BINARY_NAME-}" ]; then
	UWSGI_BINARY_NAME=uwsgi
    fi

    if [ -z "${UWSGI_PLUGIN_DIR-}" ]; then
	UWSGI_PLUGIN_DIR=${UWSGI_PREFIX:-/usr}/lib/uwsgi/plugins
    fi

    if [ -z "${UWSGI_PLUGIN_NAME-}" ]; then
	UWSGI_PLUGIN_NAME=$(find_uwsgi_plugin)
    fi

    if [ -z "${UWSGI_PYTHON_PATHNAME-}" ]; then
	UWSGI_PYTHON_PATHNAME=$(find_system_python)
    fi

    if [ -z "${UWSGI_PYTHON_VERSION-}" ]; then
	UWSGI_PYTHON_VERSION=$(get_system_python_version)
    fi

    # Set app plugin from uWSGI plugin filename
    if [ -z "${APP_PLUGIN-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	APP_PLUGIN=${UWSGI_PLUGIN_NAME%_plugin.so}
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

find_available_plugins() {
    printf $PLUGIN_FORMAT $(find_system_pythons | awk '{print $2}' | tr -d .)
}

find_installed_plugins() {
    cd $UWSGI_PLUGIN_DIR 2>/dev/null && ls "$@" 2>/dev/null || true
}

find_plugins() (
    available_plugins="$(find_available_plugins)"
    installed_plugins="$(find_installed_plugins $available_plugins)"

    if [ -n "$installed_plugins" ]; then
	printf "%s\n" $installed_plugins
    else
	printf "%s\n" $available_plugins
    fi
)

find_uwsgi_plugin() {
    if [ $UWSGI_HAS_PLUGIN = true ]; then
	find_plugins | head -n 1
    fi
}

generate_launch_agent() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $dryrun = false ]; then
	create_tmpfile
	xmlfile=$tmpfile
	cat <<-EOF >$xmlfile
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "$APPLE_URL">
	<plist version="1.0">
	  <dict>
	    <key>Label</key>
	    <string>local.$APP_NAME</string>
	    <key>RunAtLoad</key>
	    <true/>
	    <key>KeepAlive</key>
	    <true/>
	    <key>ProgramArguments</key>
	    <array>
	        <string>$(get_uwsgi_binary_path)</string>
	        <string>--plugin-dir</string>
	        <string>$UWSGI_PLUGIN_DIR</string>
	        <string>--ini</string>
	        <string>$APP_CONFIG</string>
	    </array>
	    <key>WorkingDirectory</key>
	    <string>$APP_VARDIR</string>
	  </dict>
	</plist>
	EOF
    else
	xmlfile=
    fi

    install_file 644 "$xmlfile" $1
)

get_launch_agent_label() {
    printf "%s\n" "local.$APP_NAME"
}

get_launch_agent_target() {
    printf "%s\n" "$HOME/Library/LaunchAgents/$(get_launch_agent_label).plist"
}

get_service_process() {
    ps_uwsgi $APP_UID,$USER,root | awk_uwsgi $(get_uwsgi_binary_path)
}

get_symlinks() (
    if [ -z "${UWSGI_APPDIRS-}" ]; then
	return 0
    elif [ -z "${UWSGI_ETCDIR-}" ]; then
	return 0
    elif [ ! -d $UWSGI_ETCDIR ]; then
	return 0
    else
	for dir in $UWSGI_APPDIRS; do
	    printf "%s\n" $UWSGI_ETCDIR/$dir/$APP_NAME.ini
	done
    fi
)

get_uwsgi_binary_path() {
    printf "%s/%s\n" "$UWSGI_BINARY_DIR" "$UWSGI_BINARY_NAME"
}

get_uwsgi_plugin_path() {
    if [ -n "${UWSGI_PLUGIN_DIR-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	printf "%s/%s\n" "$UWSGI_PLUGIN_DIR" "$UWSGI_PLUGIN_NAME"
    fi
}

get_uwsgi_version() {
    uwsgi=$(get_uwsgi_binary_path)

    if [ -n "$uwsgi" ] && [ -x $uwsgi ]; then
	$uwsgi --version
    else
	printf "%s\n" "<none>"
    fi
}

is_service_installed() {
    test -e $APP_CONFIG
}

is_service_running() {
    if [ -r $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)

	if [ -n "$pid" ]; then
	    if ps -p $pid >/dev/null; then
		return 0
	    else
		pid=
	    fi
	fi
    else
	pid=
    fi

    return 1
}

print_service_log_file() {
    assert [ $# -le 1 ]

    if [ -r $APP_LOGFILE ]; then
	rows="${ROWS-10}"
	header="SERVICE LOG $APP_LOGFILE (last $rows lines)"
	tail -n "$rows" $APP_LOGFILE | print_table "${1-1}" "$header"
    elif [ -e $APP_LOGFILE ]; then
	printf "%s: No read permission\n" "$APP_LOGFILE" >&2
    fi
}

print_service_processes() {
    get_service_process | print_table ${1-} ""
}

ps_uwsgi() {
    ps -U "$1" -o $PS_FORMAT
}

signal_service() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 -gt 0 ]
    wait=$1
    shift
    elapsed=0

    if [ -z "${pid-}" ]; then
	if [ -r $APP_PIDFILE ]; then
	    pid=$(cat $APP_PIDFILE 2>/dev/null)
	else
	    pid=
	fi
    fi

    if [ -z "$pid" ]; then
	return 1
    fi

    for signal in "$@"; do
	if signal_process "$signal" "$pid" "$wait"; then
	    return 0
	fi
    done

    return 1
}

signal_service_restart() {
    elapsed=0

    if is_service_running && signal_service $WAIT_SIGNAL HUP; then
	elapsed=$((elapsed + $(wait_for_timeout $((WAIT_RESTART - elapsed)))))
	restart_requested=true
    else
	restart_requested=false
    fi
}

validate_parameters_postinstallation() {
    if [ ! -d $APP_ETCDIR ]; then
	abort "%s: %s: No such configuration directory\n" "$0" "$APP_ETCDIR"
    elif [ ! -e $APP_CONFIG ]; then
	abort "%s: %s: No such configuration file\n" "$0" "$APP_CONFIG"
    elif [ ! -r $APP_CONFIG ]; then
	abort "%s: %s: No read permission\n" "$0" "$APP_CONFIG"
    elif [ ! -d $APP_DIR ]; then
	abort "%s: %s: No such program directory\n" "$0" "$APP_DIR"
    elif [ ! -d $APP_VARDIR ]; then
	abort "%s: %s: No such working directory\n" "$0" "$APP_VARDIR"
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
    binary=$(get_uwsgi_binary_path)
    plugin=$(get_uwsgi_plugin_path)

    if [ ! -d $UWSGI_BINARY_DIR ]; then
	abort "%s: %s: No such binary directory\n" "$0" "$UWSGI_BINARY_DIR"
    elif [ ! -e $binary ]; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    elif [ ! -x $binary ]; then
	abort "%s: %s: No execute permission\n" "$0" "$binary"
    elif ! $binary --version >/dev/null 2>&1; then
	abort "%s: %s: Unable to query version\n" "$0" "$binary"
    elif [ $UWSGI_HAS_PLUGIN = true ]; then
	if [ ! -d $UWSGI_PLUGIN_DIR ]; then
	    abort "%s: %s: No such plugin directory\n" "$0" "$UWSGI_PLUGIN_DIR"
	elif [ ! -e $plugin ]; then
	    abort "%s: %s: No such plugin file\n" "$0" "$plugin"
	elif [ ! -r $plugin ]; then
	    abort "%s: %s: No read permission\n" "$0" "$plugin"
	fi
    fi
}

wait_for_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    i=0

    if [ $1 -gt 0 ]; then
	while [ ! -e $APP_PIDFILE -a $i -lt $1 ]; do
	    sleep 1
	    i=$((i + 1))
	done
    fi

    if [ $i -ge $1 ]; then
	printf "Service failed to start within %s seconds\n" $1 >&2
    fi

    printf "%s\n" "$i"
}
