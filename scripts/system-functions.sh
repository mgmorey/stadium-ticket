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

control_agent() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 = load -o $1 = unload ]

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
    assert [ $1 = disable -o $1 = enable -o $1 = start -o $1 = stop ]

    target=$(get_launch_agent_target)

    if [ $dryrun = true ]; then
	check_permissions $target
    else
	case $1 in
	    (start)
		control_agent load generate_launch_agent $target
		;;
	    (stop)
		control_agent unload remove_files $target || true
		;;
	esac
    fi
}

control_brew_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 = disable -o $1 = enable -o $1 = start -o $1 = stop ]

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

control_freebsd_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 = disable -o $1 = enable -o $1 = start -o $1 = stop ]

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
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 = disable -o $1 = enable -o $1 = start -o $1 = stop ]

    if [ $dryrun = true ]; then
	return 0
    fi

    case $1 in
	(disable)
	    systemctl disable uwsgi
	    ;;
	(enable)
	    systemctl enable uwsgi
	    ;;
	(start)
	    systemctl enable uwsgi
	    systemctl restart uwsgi
	    ;;
	(stop)
	    signal_service $WAIT_SIGNAL INT TERM KILL || true
	    ;;
    esac
}

control_service() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 = disable -o $1 = enable -o $1 = start -o $1 = stop ]

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

get_system_python_version() {
    $(find_system_python) --version | awk '{print $2}'
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

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep $1 >/dev/null
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
    assert [ $2 -gt 0 ]
    printf "Sending SIG%s to process (PID: %s)\n" $3 $1

    case $3 in
	(HUP)
	    if signal_process_and_wait $1 $2 $3; then
		return 0
	    fi
	    ;;
	(*)
	    if signal_process_and_poll $1 $2 $3; then
		return 0
	    fi
	    ;;
    esac

    return 1
}

signal_process_and_poll() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $2 -ge 0 ]
    i=0

    while kill -s $3 $1 && [ $i -lt $2 ]; do
	if [ $i -eq 0 ]; then
	    printf "%s\n" "Waiting for process to exit"
	fi

	sleep 1
	i=$((i + 1))
    done

    elapsed=$((elapsed + i))
    test $i -lt $2
    return $?
}

signal_process_and_wait() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $2 -ge 0 ]

    if kill -s $3 $1; then
	printf "Waiting for process to handle SIG%s\n" "$3"
	sleep $2
	elapsed=$((elapsed + $2))
	result=0
    else
	result=1
    fi

    return $result
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
