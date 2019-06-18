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

    # Set other uWSGI parameters
    UWSGI_LOGFILE=$UWSGI_PREFIX/var/log/uwsgi.log
}

configure_darwin_source() {
    # Set uWSGI binary/plugin directories
    UWSGI_BINARY_DIR=$UWSGI_PREFIX/bin
    UWSGI_PLUGIN_DIR=$UWSGI_PREFIX/lib/uwsgi/plugins
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

    # Set other uWSGI parameters
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

    # Set other uWSGI parameters
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

    # Set uWSGI-related parameters

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

    if [ -z "${UWSGI_HAS_PLUGIN-}" ]; then
	UWSGI_HAS_PLUGIN=true
    fi

    if [ -z "${UWSGI_IS_SOURCE_ONLY-}" ]; then
	UWSGI_IS_SOURCE_ONLY=false
    fi

    if [ -z "${UWSGI_RUN_AS_SERVICE-}" ]; then
	UWSGI_RUN_AS_SERVICE=true
    fi

    # Set app plugin from uWSGI plugin filename
    if [ -z "${APP_PLUGIN-}" ]; then
	if [ -n "${UWSGI_PLUGIN_NAME-}" ]; then
	    if [ -e "$(get_uwsgi_plugin_path)" ]; then
		APP_PLUGIN=${UWSGI_PLUGIN_NAME%_plugin.so}
	    fi
	fi
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

control_agent_service() {
    target=$(get_launch_agent_target)

    if [ $dryrun = true ]; then
	check_permissions $target
    else
	case $1 in
	    (start)
		control_launch_agent load generate_launch_agent $target
		;;
	    (stop)
		control_launch_agent unload remove_files $target || true
		;;
	esac
    fi
}

control_brew_service() {
    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(start)
	    brew services restart uwsgi
	    ;;
	(stop)
	    brew services stop uwsgi
	    ;;
    esac
}

control_darwin_service() {
    if [ $UWSGI_IS_SOURCE_ONLY = true ]; then
	control_agent_service $1
    else
	control_brew_service $1
    fi
}

control_freebsd_service() {
    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(stop)
	    signal_process $WAIT_SIGNAL INT TERM KILL || true
	    ;;
    esac
}

control_linux_service() {
    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(start)
	    systemctl enable uwsgi
	    systemctl restart uwsgi
	    ;;
	(stop)
	    signal_process $WAIT_SIGNAL INT TERM KILL || true
	    ;;
    esac
}

control_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 = start -o $1 = stop ]

    case "$kernel_name" in
	(Linux)
	    control_linux_service $1
	    ;;
	(Darwin)
	    control_darwin_service $1
	    ;;
	(FreeBSD)
	    control_freebsd_service $1
	    ;;
    esac
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
    find_plugins | head -n 1
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

signal_process() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 -gt 0 ]
    elapsed=0
    wait=$1
    shift

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
	printf "Sending SIG%s to process (PID: %s)\n" $signal $pid

	case $signal in
	    (HUP)
		if signal_process_and_wait $pid $signal $wait; then
		    return 0
		fi
		;;
	    (*)
		if signal_process_and_poll $pid $signal $wait; then
		    return 0
		fi
		;;
	esac
    done

    return 1
}

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
    binary=$(get_uwsgi_binary_path)
    plugin=$(get_uwsgi_plugin_path)

    if [ ! -d $UWSGI_BINARY_DIR ]; then
	abort "%s: %s: No such binary directory\n" "$0" "$UWSGI_BINARY_DIR"
    elif [ ! -x $binary ]; then
	abort "%s: %s: No execute permission\n" "$0" "$binary"
    elif [ ! -e $binary ]; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    elif ! $binary --version >/dev/null 2>&1; then
	abort "%s: %s: Unable to query version\n" "$0" "$binary"
    elif [ $UWSGI_HAS_PLUGIN = true ]; then
	if [ ! -d $UWSGI_PLUGIN_DIR ]; then
	    abort "%s: %s: No such plugin directory\n" "$0" "$UWSGI_PLUGIN_DIR"
	elif [ ! -r $plugin ]; then
	    abort "%s: %s: No read permission\n" "$0" "$plugin"
	elif [ ! -e $plugin ]; then
	    abort "%s: %s: No such plugin file\n" "$0" "$plugin"
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
