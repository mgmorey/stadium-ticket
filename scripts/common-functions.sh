# -*- Mode: Shell-script -*-

# common-functions.sh: define commonly-used shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

KILL_COUNT=20
KILL_INTERVAL=10

SEPARATOR_SINGLE="----------------------------------------"
SEPARATOR_DOUBLE="========================================"

abort_insufficient_permissions() {
    cat >&2 <<EOF
$0: You need write permissions for $1
$0: Please retry with root privileges
EOF
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

abort_no_python() {
    abort "%s\n" "No suitable Python interpreter found"
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

check_python() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -x $1 ]
    python_output="$($1 --version || true)"

    if [ -z "$python_output" ]; then
	abort_no_python
    fi

    version="${python_output#Python }"
    printf "Python %s interpreter found: %s\n" "$version" "$1"

    if ! "$script_dir/check-python.py" "$version"; then
	abort_no_python
    fi
)

control_launch_agent() (
    assert [ -n "$1" ]
    assert [ $1 = load -o $1 = unload ]
    agent_label=local.$APP_NAME
    agent_source=macos/$agent_label.plist
    agent_target=$HOME/Library/LaunchAgents/$agent_label.plist

    case $1 in
	(load)
	    cd $source_dir
	    install_file 644 $agent_source $agent_target

	    if [ $dryrun = false ]; then
		launchctl load $agent_target
		launchctl start $agent_label
	    fi
	    ;;
	(unload)
	    if [ $dryrun = false -a -e $agent_target ]; then
		launchctl stop $agent_label
		launchctl unload $agent_target
	    fi

	    remove_files $agent_target
	    ;;
    esac
)

create_symlink() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    check_permissions "$2"

    if [ $dryrun = false ]; then
	assert [ -r "$1" ]

	if [ $1 != $2 ]; then
	    printf "Creating link %s\n" "$2"
	    /bin/ln -sf $1 $2
	fi
    fi
}

find_python() (
    python_versions=$("$script_dir/check-python.py")

    if pyenv --version >/dev/null 2>&1; then
	which="pyenv which"
    else
	which=which
    fi

    for version in ${python_versions-$PYTHON_VERSIONS} ""; do
	python=$($which python$version 2>/dev/null || true)

	if [ -z "$python" ]; then
	    :
	elif [ $python = false ]; then
	    abort_no_python
	elif $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return
	fi
    done
)

find_system_python () (
    python_versions=$("$script_dir/check-python.py")

    for prefix in /usr/local /usr; do
	python_dir=$prefix/bin

	if [ -d $python_dir ]; then
	    for version in ${python_versions-$PYTHON_VERSIONS} ""; do
		python=$python_dir/python$version

		if [ -x $python ]; then
		    if $python --version >/dev/null 2>&1; then
			printf "%s\n" "$python"
			return
		    fi
		fi
	    done
	fi
    done
)

install_file() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a -n "$3" ]
    check_permissions $3

    if [ $dryrun = false ]; then
	printf "Installing file %s as %s\n" "$2" "$3"
	install -d -m 755 "$(dirname "$3")"
	install -C -m $1 $2 $3
    fi
}

print_file_tail() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" -a -n "$tmpfile" ]
    tail $1 >$tmpfile

    if [ ! -s "$tmpfile" ]; then
	return
    fi

    printf "%s\n" $SEPARATOR_DOUBLE$SEPARATOR_DOUBLE
    printf "%s\n" "Contents of $1 (last 10 lines)"
    printf "%s\n" $SEPARATOR_SINGLE$SEPARATOR_SINGLE
    cat $tmpfile
    printf "%s\n" $SEPARATOR_DOUBLE$SEPARATOR_DOUBLE
}

remove_database() {
    if [ -n "${DATABASE_FILENAME-}" ]; then
	remove_files $DATABASE_FILENAME
    fi
}

remove_files() {
    check_permissions "$@"

    if [ "$dryrun" = false ]; then
	printf "Removing %s\n" "$@" | sort -u
	/bin/rm -rf "$@"
    fi
}

signal_service() {
    pid=$("$script_dir/read-file.sh" $APP_PIDFILE)
    result=1

    if [ -z "$pid" ]; then
	return $result
    fi

    for signal in "$@"; do
	if [ $result -gt 0 ]; then
	    printf "Sending SIG%s to process (pid: %s)\n" $signal $pid
	fi

	if [ $signal = HUP ]; then
	    if kill -s $signal $pid; then
		printf "Waiting for process to handle SIG%s\n" "$signal"
		sleep $KILL_INTERVAL
		result=0
	    else
		break
	    fi
	else
	    printf "%s\n" "Waiting for process to die"
	    i=0

	    while kill -s $signal $pid && [ $i -lt $KILL_COUNT ]; do
		sleep 1
		i=$((i + 1))
	    done

	    if [ $i -lt $KILL_COUNT ]; then
		result=0
		break
	    fi
	fi
    done

    return $result
}

tail_file() {
    assert [ -n "$1" -a -n "$tmpfile" ]

    if [ -r $1 ]; then
	print_file_tail $1
    elif [ -e $1 ]; then
	printf "%s: No permission to read file\n" "$1" >&2
    fi
}
