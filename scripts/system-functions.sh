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
    ps_uwsgi $APP_UID,$USER | awk_uwsgi $UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME
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

is_service_installed() {
    test -e $APP_CONFIG
}

is_service_running() {
    if [ -e $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)
	if [ -n "$pid" ] && ps -p $pid >/dev/null; then
	    return 0
	fi
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
	    if [ $UWSGI_SOURCE_ONLY = true ]; then
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
	    (Linux)
		signal_service $WAIT_SIGNAL INT TERM KILL || true
		;;
	    (Darwin)
		control_launch_agent unload remove_files || true
		;;
	esac
    fi
}

wait_for_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]
    i=0

    if [ $2 -gt 0 ]; then
	while [ ! -e $1 -a $i -lt $2 ]; do
	    sleep 1
	    i=$((i + 1))
	done
    fi

    if [ $i -ge $2 ]; then
	printf "Service failed to start within %s seconds\n" $2 >&2
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
