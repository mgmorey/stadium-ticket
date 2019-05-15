# -*- Mode: Shell-script -*-

# virtualenv-functions.sh: virtual environment shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

PIP_19_OPTS="--no-cache-dir --no-warn-script-location"
PIP_OPTS="--no-cache-dir"

activate_virtualenv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

create_virtualenv() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	if [ -z "${python-${2-}}" ]; then
	    python=$(find_development_python)
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

get_pip_options() {
    case "$($pip --version | awk '{print $2}')" in
	(19.*)
	    printf "%s\n" "$PIP_19_OPTS"
	    ;;
	(*)
	    printf "%s\n" "$PIP_OPTS"
	    ;;
    esac
}

pip_upgrade() {
    pip=$("$script_dir/get-python-command.sh" pip)
    pip_opts=

    if [ "$pip" = false ]; then
	return
    fi

    printf "%s\n" "Upgrading user packages via pip"
    $pip install $(get_pip_options) --upgrade --user "$@"
}

sync_requirements() {
    assert [ "$pip" != false ]
    printf "%s\n" "Installing required packages via pip"
    $pip install $(printf -- "-r %s\n" ${venv_requirements:-requirements.txt})
}

sync_virtualenv() {
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
	pip_upgrade pip virtualenv
	create_virtualenv "$@"
	sync=true
    fi

    if [ -r $1/bin/activate ]; then
	activate_virtualenv $1
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
