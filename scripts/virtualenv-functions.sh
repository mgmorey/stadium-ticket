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

activate_venv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

create_venv() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    upgrade_venv_tools pip virtualenv
    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	if [ -z "${python-${2-}}" ]; then
	    python=$(find_python)
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

sync_requirements() {
    assert [ "$pip" != false ]
    printf "%s\n" "Installing required packages"
    pip_install="$pip install${SUDO_USER:+ $PIP_SUDO_OPTS}"
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

upgrade_venv_tools() {
    pip=$("$script_dir/get-python-command.sh" pip)

    if [ "$pip" = false ]; then
	return
    fi

    printf "%s\n" "Upgrading pip and virtualenv"
    pip_opts="$PIP_OPTS${SUDO_USER:+ $PIP_SUDO_OPTS}"
    pip_opts="$pip_opts --upgrade --user"
    upgrade="$pip install $pip_opts"
    run_unprivileged $upgrade "$@"
}
