# -*- Mode: Shell-script -*-

# system-functions.sh: define system shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

APPLE_URL=http://www.apple.com/DTDs/PropertyList-1.0.dtd
AWK_FORMAT='NR == 1 || $%d == binary {print $0}\n'
PLUGIN_FORMAT="python%s_plugin.so\n"

WAIT_DEFAULT=2
WAIT_RESTART=10

abort_insufficient_permissions() {
    cat <<-EOF >&2
	$0: Write access required to update file or directory: $1
	$0: Insufficient access to complete the requested operation.
	$0: Please try the operation again as a privileged user.
	EOF
    exit 1
}

awk_uwsgi() {
    awk "$(printf "$AWK_FORMAT" $PS_COLUMN)" binary="$1"
}

check_permissions() (
    for file; do
	if [ -e $file -a -w $file ]; then
	    :
	else
	    dir=$(dirname $file)

	    if [ $dir != . -a $dir != / ]; then
		check_permissions $dir
	    else
		abort_insufficient_permissions $file
	    fi
	fi
    done
)

control_launch_agent() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    agent_label=local.$APP_NAME
    agent_target=$HOME/Library/LaunchAgents/$agent_label.plist

    case $1 in
	(load)
	    assert [ $# -eq 2 ]
	    assert [ -n "$2" ]
	    $2 $agent_target

	    if [ $dryrun = false ]; then
		launchctl load $agent_target
	    fi
	    ;;
	(restart)
	    control_launch_agent stop
	    control_launch_agent start
	    ;;
	(start|stop)
	    if [ $dryrun = false -a $1 = start -o -e $agent_target ]; then
		launchctl $1 $agent_label
	    fi
	    ;;
	(unload)
	    assert [ $# -eq 2 ]
	    assert [ -n "$2" ]

	    if [ $dryrun = false -a -e $agent_target ]; then
		launchctl unload $agent_target
	    fi

	    $2 $agent_target
	    ;;
    esac
)

find_system_python() (
    find_system_pythons | awk 'NR == 1 {print $1}'
)

find_system_pythons() (
    for python_version in $PYTHON_VERSIONS; do
	for prefix in /usr /usr/local; do
	    python_dir=$prefix/bin

	    if [ -d $python_dir ]; then
		python=$python_dir/python$python_version

		if [ -x $python ]; then
		    if $python --version >/dev/null 2>&1; then
			printf "%s %s\n" "$python" "$python_version"
		    fi
		fi
	    fi
	done
    done

    return 1
)

find_uwsgi_plugin() {
    find_uwsgi_plugins | head -n 1
}

find_uwsgi_plugins() (
    available_plugins="$(find_uwsgi_available_plugins)"
    installed_plugins="$(find_uwsgi_installed_plugins $available_plugins)"

    if [ -n "$installed_plugins" ]; then
	printf "%s\n" $installed_plugins
    else
	printf "%s\n" $available_plugins
    fi
)

find_uwsgi_available_plugins() {
    printf $PLUGIN_FORMAT $(find_system_pythons | awk '{print $2}' | tr -d .)
}

find_uwsgi_installed_plugins() {
    cd $UWSGI_PLUGIN_DIR 2>/dev/null && ls "$@" 2>/dev/null || true
}

generate_launch_agent_plist() (
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
	        <string>$UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME</string>
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

get_service_process() {
    ps_uwsgi $APP_UID,$USER,root | awk_uwsgi $UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME
}

get_service_status() {
    if is_service_installed; then
	if is_service_running; then
	    printf "%s\n" running
	else
	    printf "%s\n" stopped
	fi
    else
	printf "%s\n" uninstalled
    fi
}

get_setpriv_command() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    setpriv="setpriv --reuid $(id -u $1) --regid $(id -g $1)"
    version="$(setpriv --version 2>/dev/null)"

    case "${version##* }" in
	('')
	    return 1
	    ;;
	([01].*)
	    options="--clear-groups"
	    ;;
	(2.[0-9].*)
	    options="--clear-groups"
	    ;;
	(2.[12][0-9].*)
	    options="--clear-groups"
	    ;;
	(2.3[012].*)
	    options="--init-groups"
	    ;;
	(*)
	    options="--init-groups --reset-env"
	    ;;
    esac

    printf "$setpriv %s %s\n" "$options"
    return 0
)

get_su_command() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "$kernel_name" in
	(Linux)
	    if get_setpriv_command $1; then
		return 0
	    else
		options=-l
	    fi
	    ;;
	(Darwin)
	    options=-l
	    ;;
	(FreeBSD)
	    options=-l
	    ;;
	(*)
	    options=-
	    ;;
    esac

    printf "su %s %s\n" "$options" "$1"
    return 0
)

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

install_file() {
    assert [ $# -eq 3 ]
    assert [ -n "$3" ]

    if [ $dryrun = true ]; then
	check_permissions $3
    else
	assert [ -n "$1" ]
	assert [ -n "$2" ]
	assert [ -r $2 ]

	if is_tmpfile $2; then
	    printf "Generating file %s\n" "$3"
	else
	    printf "Installing file %s as %s\n" "$2" "$3"
	fi

	install -d -m 755 "$(dirname "$3")"
	install -C -m $1 $2 $3
    fi
}

is_installed() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian|ubuntu)
		    status=$(dpkg-query -Wf '${Status}\n' $1 2>/dev/null)
		    test "$status" = "install ok installed"
		    ;;
		(opensuse-*|fedora|redhat|centos)
		    rpm --query $1 >/dev/null 2>&1
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    brew list 2>/dev/null | grep -E '^'"$1"'$' >/dev/null
	    ;;
	(FreeBSD)
	    pkg query %n "$1" >/dev/null 2>&1
	    ;;
	(*)
	    false
	    ;;
    esac
)

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

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep $1 >/dev/null
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

print_table() {
    "$script_dir/print-table.awk" -v border="${1-1}" \
				  -v header="${2-}" \
				  -v width="${COLUMNS-80}"
}

ps_uwsgi() {
    ps -U "$1" -o $PS_FORMAT
}

remove_files() {
    if [ $# -eq 0 ]; then
	return 0
    fi

    if [ $dryrun = true ]; then
	check_permissions "$@"
    else
	printf "Removing %s\n" $(printf "%s\n" "$@" | sort -u)
	/bin/rm -rf "$@"
    fi
}

request_service_start() {
    case "$kernel_name" in
	(Linux)
	    systemctl enable uwsgi
	    systemctl restart uwsgi
	    ;;
	(Darwin)
	    if [ $UWSGI_IS_SOURCE_ONLY = true ]; then
		control_launch_agent load generate_launch_agent_plist
	    else
		brew services restart uwsgi
	    fi
	    ;;
    esac
}

request_service_stop() {
    if [ $dryrun = false ]; then
	case "$kernel_name" in
	    (Linux|FreeBSD)
		signal_process $WAIT_SIGNAL INT TERM KILL || true
		;;
	    (Darwin)
		control_launch_agent unload remove_files || true
		;;
	esac
    fi
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

signal_process_and_poll() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 ]
    i=0

    while kill -s $2 $1 2>/dev/null && [ $i -lt $3 ]; do
	if [ $i -eq 0 ]; then
	    printf "%s\n" "Waiting for process to exit"
	fi

	sleep 1
	i=$((i + 1))
    done

    elapsed=$((elapsed + i))
    test $i -lt $3
    return $?
}

signal_process_and_wait() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 ]

    if kill -s $2 $1 2>/dev/null; then
	printf "Waiting for process to handle SIG%s\n" "$2"
	sleep $3
	elapsed=$((elapsed + $3))
	result=0
    else
	result=1
    fi

    return $result
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

wait_for_timeout() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $1 -gt 0 ]; then
	sleep $1
	printf "%s\n" "$1"
    else
	printf "%s\n" 0
    fi
}
