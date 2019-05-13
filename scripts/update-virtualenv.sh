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

: ${LANG:=en_US.UTF-8}
: ${LC_ALL:=en_US.UTF-8}
export LANG LC_ALL

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

pipenv_init() {
    if ! $pipenv --venv >/dev/null 2>&1; then
	if pyenv --version >/dev/null 2>&1; then
	    python=$(find_development_python)
	    check_python $python
	    $pipenv --python $python
	else
	    $pipenv $PIPENV_OPTS
	fi
    fi
}

pipenv_lock() {
    pipenv_init
    $pipenv lock -d
    create_tmpfile

    for file; do
	case $file in
	    (requirements-dev*.txt)
		pipenv_opts=-dr
		;;
	    (requirements.txt)
		pipenv_opts=-r
		;;
	    (*)
		abort "%s: %s: Invalid filename\n" "$0" "$file"
		;;
	esac

	printf "Generating %s\n" $file

	if $pipenv lock $pipenv_opts >$tmpfile; then
	    /bin/mv -f $tmpfile $file
	else
	    abort "%s: Unable to update %s\n" "$0" "$file"
	fi
    done

    chgrp $(id -g) "$@"
    chmod a+r "$@"
}

if [ -n "${VIRTUAL_ENV:-}" ]; then
    abort "%s: Must not be run within a virtual environment\n" "$0"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/virtualenv-functions.sh"

pipenv=$("$script_dir/get-python-command.sh" pipenv)

if [ "$pipenv" = false ]; then
    pip=$("$script_dir/get-python-command.sh" pip)
fi

source_dir=$script_dir/..

cd "$source_dir"

if [ "$pipenv" != false ]; then
    pipenv_lock $VENV_REQUIREMENTS
    $pipenv sync -d
elif [ "$pip" != false ]; then
    venv_force_sync=true
    venv_requirements=$VENV_REQUIREMENTS
    sync_virtualenv $VENV_FILENAME
else
    abort "%s: Neither pip nor pipenv found in PATH\n" "$0"
fi
