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

AWK_FMT='NR == 1 || $%s == command {print $0}'

abort_insufficient_permissions() {
    cat <<-EOF >&2
	$0: Write access required to update file or directory: $1
	$0: Insufficient access to complete the requested operation.
	$0: Please try the operation again as a privileged user.
	EOF
    exit 1
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

get_service_parameters() {
    cat <<-EOF
	             Name: $APP_NAME
	             Port: $APP_PORT
	          User ID: $APP_UID
	         Group ID: $APP_GID
	    Configuration: $APP_CONFIG
	   Code directory: $APP_DIR
	   Data directory: $APP_VARDIR
	         Log file: $APP_LOGFILE
	         PID file: $APP_PIDFILE
	     uWSGI binary: $UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME
EOF

    if [ -n "${UWSGI_PLUGIN_DIR-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	cat <<-EOF
	     uWSGI plugin: $UWSGI_PLUGIN_DIR/$UWSGI_PLUGIN_NAME
EOF
    fi
}

get_service_process() {
    uwsgi=$UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME
    $UWSGI_PS | awk "$(printf "$AWK_FMT" $UWSGI_PS_COL)" command=$uwsgi
}

print_service_parameters() {
    get_service_parameters | print_table "SERVICE PARAMETER: VALUE" ${1-}
}

print_service_log_file() {
    assert [ $# -le 1 ]

    if [ -r $APP_LOGFILE ]; then
	rows="${ROWS-10}"
	header="SERVICE LOG $APP_LOGFILE (last $rows lines)"
	tail -n "$rows" $APP_LOGFILE | print_table "$header" ${1-}
    elif [ -e $APP_LOGFILE ]; then
	printf "%s: No read permission\n" "$APP_LOGFILE" >&2
    fi
}

print_service_process() {
    get_service_process | print_table "" ${1-}
}

print_table() {
    "$script_dir/print-table.awk" -v header="$1" \
				  -v footer="${2-1}" \
				  -v columns="${COLUMNS-96}"
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

signal_service() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 -gt 0 ]
    elapsed=0
    wait=$1
    shift

    pid=$(cat $APP_PIDFILE 2>/dev/null)

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
