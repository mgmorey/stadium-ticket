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

DOUBLE="======================================================================"
SINGLE="----------------------------------------------------------------------"
KILL_COUNT=20
KILL_INTERVAL=5

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

activate_venv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

check_permissions() {
    for file; do
	if [ -e $file -a -w $file ]; then
	    :
	elif [ $file != . -a $file != / ]; then
	    check_permissions $(dirname $file)
	else
	    abort_insufficient_permissions $file
	fi
    done
}

check_python_version() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -x $1 ]
    python_output=$($1 --version)
    python_version="${python_output#Python }"
    printf "Python %s interpreter found: %s\n" "$python_version" "$1"

    if ! $script_dir/check-python-version.py "$python_version"; then
	abort_no_python
    fi
}

create_venv() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	python="${2-}"

	if [ -z "$python" ]; then
	    if pyenv --version >/dev/null 2>&1; then
		which="pyenv which"
	    else
		which=which
	    fi

	    python=$($which $PYTHON)

	    if [ -z "$python" ]; then
		abort_no_python
	    fi
	fi
    fi

    check_python_version $python
    printf "%s\n" "Creating virtual environment"

    if [ "$virtualenv" != false ]; then
	$virtualenv -p $python $1
    elif [ "$pyvenv" != false ]; then
	$pyvenv $1
    else
	abort "%s: No virtualenv nor pyenv/venv command found\n" "$0"
    fi
}

sync_requirements() {
    assert [ "$pip" != false ]
    printf "%s\n" "Upgrading pip"
    pip_install="$pip install ${SUDO_USER:+--no-cache-dir}"
    $pip_install --upgrade pip
    printf "%s\n" "Installing required packages"
    $pip_install $(printf -- "-r %s\n" ${venv_requirements:-requirements.txt})
}

sync_venv() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    if [ -n "${VIRTUAL_ENV:-}" -a -d "$1" ]; then
	stats_1="$(stat -Lf "%d %i" "$VIRTUAL_ENV")"
	stats_2="$(stat -Lf "%d %i" "$1")"

	if [ "$stats_1" = "$stats_2" ]; then
	    abort "%s: Must not be run within the virtual environment\n" "$0"
	fi
    fi

    if [ -d $1 ]; then
	sync=false
    else
	upgrade_pip_and_virtualenv
	create_venv "$@"
	sync=true
    fi

    if [ -r $1/bin/activate ]; then
	activate_venv $1
	assert [ -n "${VIRTUAL_ENV:-}" ]

	if [ "${venv_force_sync:-$sync}" = true ]; then
	    sync_requirements
	fi
    elif [ -d $1 ]; then
	abort "%s: Unable to activate environment\n" "$0"
    else
	abort "%s: No virtual environment\n" "$0"
    fi
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

print_file_tail() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" -a -n "$tmpfile" ]
    tail $1 >$tmpfile

    if [ ! -s "$tmpfile" ]; then
	return
    fi

    printf "%s\n" ""
    printf "%s\n" $DOUBLE
    printf "%s\n" "Contents of $APP_LOGFILE (last 10 lines)"
    printf "%s\n" $SINGLE
    cat $tmpfile
    printf "%s\n" $SINGLE
    printf "%s\n" ""
}

signal_app() {
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

tail_log_file() {
    assert [ -n "$APP_LOGFILE" -a -n "$tmpfile" ]

    if [ -r $APP_LOGFILE ]; then
	print_file_tail $APP_LOGFILE
    elif [ -e $APP_LOGFILE ]; then
	printf "No permission to read log file: %s\n" $APP_LOGFILE >&2
    fi
}

upgrade_pip_and_virtualenv() {
    pip=$("$script_dir/get-python-command.sh" pip)

    if [ "$(id -u)" -eq 0 ]; then
	sh="su $SUDO_USER"
    else
	sh="sh -eu"
    fi

    if [ "$pip" != false ]; then
	pip_install="$pip install ${SUDO_USER:+$PIP_SUDO_OPTS}"
	$sh -c "$pip_install --upgrade --user pip virtualenv"
    fi
}
