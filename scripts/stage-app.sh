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

PIP=pip3
PYTHON=python3

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
    pip_venvname=$1
    . $script_dir/pip-sync-virtualenv.sh
}

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

for pip in $PIP "$PYTHON -m pip" false; do
    if $pip >/dev/null 2>&1; then
	break
    fi
done

# Use no cache if child process of sudo
pip_opts=${SUDO_USER:+--no-cache-dir}

script_dir=$(realpath "$(dirname "$0")")
source_dir=$script_dir/..

cd $source_dir

stage_app $1
