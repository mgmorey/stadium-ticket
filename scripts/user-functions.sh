# -*- Mode: Shell-script -*-

# user-functions.sh: define user shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

PIP_9_UPGRADE_OPTS="--no-cache-dir"
PIP_10_UPGRADE_OPTS="--no-cache-dir --no-warn-script-location"

abort_no_python() {
    abort "%s\n" "No suitable Python interpreter found"
}

activate_virtualenv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

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

    if ! $1 "$script_dir/check-python.py" "$version"; then
	abort_no_python
    fi
)

create_virtualenv() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	if [ -z "${python-${2-}}" ]; then
	    python=$(find_user_python)
	fi
    fi

    check_python $python
    printf "%s\n" "Creating virtual environment"

    if [ "$virtualenv" != false ]; then
	$virtualenv -p $python $1
    elif [ "$pyvenv" != false ]; then
	$pyvenv $1
    else
	abort "%s: No virtualenv nor pyenv/venv command found\n" "$0"
    fi
}

get_home_directory() {
    if [ "$kernel_name" = Darwin -a "$1" = $USER ]; then
	printf "%s\n" "$HOME"
    else
	getent passwd ${1-$USER} | awk -F: '{print $6}'
    fi
}

get_pip_upgrade_options() {
    case "$($pip --version | awk '{print $2}')" in
	([0-9].*)
	    printf "%s\n" "$PIP_9_UPGRADE_OPTS"
	    ;;
	(*)
	    printf "%s\n" "$PIP_10_UPGRADE_OPTS"
	    ;;
    esac
}

reset_home_directory() {
    if [ -z "${SUDO_USER-}" ]; then
	return 0
    fi

    home_dir="$(get_home_directory $SUDO_USER)"

    if [ "$HOME" != "$home_dir" ]; then
	export HOME="$home_dir"
    fi
}

sync_requirements_via_pip() {
    printf "%s\n" "Installing required packages via pip"
    $pip install $(printf -- "-r %s\n" ${venv_requirements:-requirements.txt})
}

sync_virtualenv_via_pip() {
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
	sync=true
    fi

    if [ $sync = true ]; then
	upgrade_via_pip pip virtualenv
	create_virtualenv "$@"
    fi

    if [ -r $1/bin/activate ]; then
	activate_virtualenv $1
	assert [ -n "${VIRTUAL_ENV:-}" ]

	if [ "${venv_force_sync:-$sync}" = true ]; then
	    sync_requirements_via_pip
	fi
    elif [ -d $1 ]; then
	abort "%s: Unable to activate environment\n" "$0"
    else
	abort "%s: No virtual environment\n" "$0"
    fi
}

upgrade_via_pip() (
    pip=$("$script_dir/get-python-command.sh" pip)

    if [ "$pip" = false ]; then
	return
    fi

    printf "%s\n" "Upgrading user packages via pip"
    $pip install $(get_pip_upgrade_options) --upgrade --user "$@"
)
