#!/bin/sh -eu

# stage-app.sh: stage uWSGI application
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

PIP=pip
PYTHON=python3
VENV_REQS="requirements.txt"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

stage_app() {
    assert [ -n "$1" ]
    venv_name=$1
    venv_reqs=$VENV_REQS
    . $script_dir/pip-sync-virtualenv.sh
}

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must be run as a non-privileged user"
fi

script_dir=$(realpath "$(dirname "$0")")

source_dir=$script_dir/..

cd $source_dir

pip=$(sh -eu $script_dir/get-python-command.sh $PIP $PYTHON)
pipenv=$(sh -eu $script_dir/get-python-command.sh pipenv $PYTHON)

stage_app $1
