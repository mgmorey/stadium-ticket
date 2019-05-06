# -*- Mode: Shell-script -*-

# sync-virtualenv.sh: deploy Python virtual environment
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

PIP_SUDO_OPTS="--no-cache-dir"
PYTHON=python3

activate_venv() {
    assert [ -n "$1" -a -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

create_venv() {
    assert [ -n "$1" ]
    printf "%s\n" "Creating virtual environment"
    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	$virtualenv -p $PYTHON $1
    elif [ "$pyvenv" != false ]; then
	$pyvenv $1
    else
	abort "%s: Unable to create virtual environment\n" "$0"
    fi
}

sync_requirements() {
    assert [ "$pip" != false ]
    printf "%s\n" "Upgrading pip"
    pip_install="$pip install ${SUDO_USER:+$PIP_SUDO_OPTS}"
    $pip_install --upgrade pip
    printf "%s\n" "Installing required packages"
    $pip_install $(printf -- "-r %s\n" ${venv_requirements:-requirements.txt})
}

sync_venv() {
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
	create_venv $1
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
