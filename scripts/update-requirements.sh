#!/bin/sh -eu

# update-requirements: update requirements and virtualenv
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
REQUIREMENTS="requirements-dev.txt requirements.txt"

abort() {
    printf "$@" >&2
    exit 1
}

pip_update() {
    if [ ! -d .venv ]; then
	printf "%s\n" "Creating virtual environment"
	$PYTHON -m venv .venv
    fi

    if [ -d .venv ]; then
	printf "%s\n" "Activating virtual environment"
	. .venv/bin/activate
	. "$script_dir/sync-virtualenv.sh"
    else
	abort "%s\n" "No virtual environment"
    fi
}

pipenv_lock() {
    $pipenv lock

    for file; do
	case $file in
	    (requirements-dev*.txt)
		opts=-d
		;;
	    (requirements.txt)
		opts=
		;;
	    (*)
		abort "%s: Invalid filename\n" "$file"
	esac

	printf "Generating %s\n" "$file"
	if $pipenv lock $opts -r >$tmpfile; then
	    /bin/mv -f $tmpfile "$file"
	    chgrp $(id -g) "$file"
	    chmod a+r "$file"
	else
	    abort "Unable to update %s\n" "$file"
	fi
    done
}

pipenv_update() {
    export LANG=${LANG:-en_US.UTF-8}
    export LC_ALL=${LC_ALL:-en_US.UTF-8}
    pipenv_lock $REQUIREMENTS
    pipenv sync -d
}

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "This script must be run as a non-privileged user"
fi

pipenv=$(which pipenv 2>/dev/null || true)
script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

cd "$source_dir"
tmpfile=$(mktemp)

trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

if [ -n "$pipenv" ]; then
    pipenv_update
else
    pip_update
fi

touch .update
