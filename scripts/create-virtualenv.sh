#!/bin/sh -eu

# create-virtualenv.sh: create Python virtual environment
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

PYTHON=python3

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

create_venv() {
    if [ ! -d "$1" ]; then
	printf "%s\n" "Creating virtual environment"

	if [ "$virtualenv" != false ]; then
	    $virtualenv -p $PYTHON "$1"
	else
	    $PYTHON -m venv "$1"
	fi
    fi
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

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    pathname_1="$(readlink -e "$(realpath "$VIRTUAL_ENV")")"
    pathname_2="$(readlink -e "$(realpath "$1")")"

    if [ "$pathname_1" = "$pathname_2" ]; then
	abort "%s\n" "$0: Must not be run within the virtual environment"
    fi
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must be run as a non-privileged user"
fi

for virtualenv in virtualenv "$PYTHON -m virtualenv" false; do
    if $virtualenv >/dev/null 2>&1; then
	break
    fi
done

create_venv $1
