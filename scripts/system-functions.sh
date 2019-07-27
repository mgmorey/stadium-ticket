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

WAIT_DEFAULT=5
WAIT_RESTART=10
WAIT_SIGNAL=10

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
	if [ ! -w "$file" ]; then
	    dir="$(dirname "$file")"

	    if [ "$dir" = / ]; then
		abort_insufficient_permissions "$file"
	    else
		check_permissions "$dir"
	    fi
	fi
    done
)

control_agent() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]

    case $1 in
	(load)
	    assert [ $# -eq 3 ]
	    assert [ -n "$2" ]
	    assert [ -n "$3" ]
	    $2 $3

	    if [ $dryrun = false ]; then
		launchctl load $3
	    fi
	    ;;
	(unload)
	    assert [ $# -eq 3 ]
	    assert [ -n "$2" ]
	    assert [ -n "$3" ]

	    if [ $dryrun = false -a -e $3 ]; then
		launchctl unload $3
	    fi

	    $2 $3
	    ;;
    esac
)

control_agent_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    target=$(get_launch_agent_target)

    if [ $dryrun = true ]; then
	check_permissions $target
    else
	case $1 in
	    (restart)
		if [ ! -e $target ]; then
		    control_agent load generate_launch_agent $target
		fi
		;;
	    (stop)
		if [ -e $target ]; then
		    control_agent unload remove_files $target
		fi
		;;
	esac
    fi
}

control_brew_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(restart)
	    brew services start uwsgi
	    ;;
	(stop)
	    brew services stop uwsgi
	    ;;
    esac
}

control_darwin_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ $2 = false ]; then
	control_agent_service $1
    else
	control_brew_service $1
    fi
}

control_freebsd_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(stop)
	    signal_service $WAIT_SIGNAL INT TERM KILL || true
	    ;;
    esac
}

control_linux_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(disable|enable)
	    systemctl $1 uwsgi
	    ;;
	(restart)
	    systemctl restart uwsgi
	    ;;
	(stop)
	    signal_service $WAIT_SIGNAL INT TERM KILL || true
	    ;;
    esac
}

control_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    case "$kernel_name" in
	(Linux|GNU)
	    control_linux_service $1 $2
	    ;;
	(Darwin)
	    control_darwin_service $1 $2
	    ;;
	(FreeBSD)
	    control_freebsd_service $1 $2
	    ;;
    esac
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
	(Linux|GNU)
	    if get_setpriv_command $1; then
		return 0
	    else
		options=-l
	    fi
	    ;;
	(Darwin|FreeBSD)
	    options=-l
	    ;;
	(*)
	    options=-
	    ;;
    esac

    printf "su %s %s\n" "$options" "$1"
    return 0
)

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
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu)
		    status=$(dpkg-query -Wf '${Status}\n' $1 2>/dev/null)
		    test "$status" = "install ok installed"
		    ;;
		(opensuse-*|fedora|redhat|centos|ol)
		    rpm --query $1 >/dev/null 2>&1
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    brew list 2>/dev/null | grep -qE '^'"$1"'$'
	    ;;
	(FreeBSD)
	    pkg query %n "$1" >/dev/null 2>&1
	    ;;
	(*)
	    false
	    ;;
    esac
)

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep -q $1
}

print_elapsed_time() {
    if [ $elapsed -eq 0 ]; then
	return 0
    fi

    printf "Service %s %s in %d seconds\n" "$APP_NAME" "$1" "$elapsed"
}

print_table() {
    "$script_dir/print-table.awk" -v border="${1-1}" \
				  -v header="${2-}" \
				  -v width="${COLUMNS-80}"
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

signal_process() {
    assert [ $# -ge 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]
    printf "Sending SIG%s to process (PID: %s)\n" $1 $2

    case $1 in
	(HUP)
	    signal_process_and_wait "$@"
	    ;;
	(*)
	    signal_process_and_poll "$@"
	    ;;
    esac
}

signal_process_and_poll() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]
    i=0

    while kill -s $1 $2 && [ $i -lt $3 ]; do
	if [ $i -eq 0 ]; then
	    printf "%s\n" "Waiting for process to exit"
	fi

	sleep 1
	i=$((i + 1))
    done

    elapsed=$((elapsed + i))
    test $i -lt $3
}

signal_process_and_wait() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 -a $3 -le 60 ]

    if kill -s $1 $2; then
	printf "Waiting for process to handle SIG%s\n" "$1"
	sleep $3
	elapsed=$((elapsed + $3))
	return 0
    fi

    return 1
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
