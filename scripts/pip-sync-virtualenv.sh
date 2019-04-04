# -*- Mode: Shell-script -*-

# pip-sync-virtualenv.sh: deploy PIP virtual environment
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

activate_venv() {
    assert [ -n "$1" ] && [ -d $1/bin ] && [ -r "$1/bin/activate" ]
    printf "%s\n" "Activating virtual environment"
    assert [ -r "$1/bin/activate" ]
    set +u
    . "$1/bin/activate"
    set -u
}

pip_sync_requirements() {
    assert [ "$pip" != false ]
    printf "%s\n" "Upgrading pip"
    $pip install $pip_opts --upgrade pip
    printf "%s\n" "Installing required packages"
    $pip install $pip_opts $(printf -- "-r %s\n" ${REQUIREMENTS:-requirements.txt})
}

pip_sync_venv() {
    assert [ -n "$1" ]
    assert [ -z "${VIRTUAL_ENV:-}" ]

    if [ ! -d $1 ]; then
	sync=true
    else
	sync=false
    fi

    sh -eu $script_dir/create-virtualenv.sh $1

    if [ -r $1/bin/activate ]; then
	activate_venv $1
	assert [ -n "${VIRTUAL_ENV:-}" ]

	if [ "${pip_venvsync:-$sync}" = true ]; then
	    pip_sync_requirements
	fi
    elif [ -d $1 ]; then
	abort "%s\n" "$0: Unable to activate environment"
    else
	abort "%s\n" "$0: No virtual environment"
    fi
}

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must run as a non-privileged user"
fi

pip_sync_venv $pip_venvname
