#!/bin/sh -eu

# update-virtualenv: update virtualenv dependencies
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

export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

VENV_FILENAME=.venv
VENV_REQUIREMENTS="requirements-dev.txt requirements.txt"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

pipenv_lock() {
    assert [ "$pipenv" != false ]
    $pipenv lock

    for file; do
	case $file in
	    (requirements-dev*.txt)
		pipenv_opts=-dr
		;;
	    (requirements.txt)
		pipenv_opts=-r
		;;
	    (*)
		abort "%s: Invalid filename\n" $file
	esac

	printf "Generating %s\n" $file

	if $pipenv lock $pipenv_opts >$tmpfile; then
	    /bin/mv -f $tmpfile $file
	else
	    abort "Unable to update %s\n" $file
	fi
    done

    chgrp $(id -g) "$@"
    chmod a+r "$@"
}

pipenv_update() {
    pipenv_lock $VENV_REQUIREMENTS
    $pipenv sync -d
}

pip_update() {
    assert [ -n "$1" ]
    venv_filename=$1
    venv_force_sync=true
    venv_requirements=$VENV_REQUIREMENTS
    . $script_dir/sync-virtualenv.sh
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

if [ -n "${VIRTUAL_ENV:-}" ]; then
    abort "%s\n" "$0: Must not be run within a virtual environment"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must be run as a non-privileged user"
fi

script_dir=$(realpath "$(dirname "$0")")

source_dir=$script_dir/..

tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

cd $source_dir

pipenv=$(sh -eu $script_dir/get-python-command.sh pipenv)

if [ "$pipenv" = false ]; then
    pip=$(sh -eu $script_dir/get-python-command.sh pip)

if [ "$pipenv" != false ]; then
    pipenv_update
elif [ "$pip" != false ]; then
    pip_update $VENV_FILENAME
else
    abort "$0: No pip nor pipenv in path"
fi

touch .update
