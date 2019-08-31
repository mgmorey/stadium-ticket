#!/bin/sh -eu

# refresh-virtualenv: install virtual environment dependencies
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

generate_requirements_files() (
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
)

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

refresh_via_pipenv() {
    if ! $pipenv --venv >/dev/null 2>&1; then
	upgrade_via_pip pip pipenv || true

	if pyenv --version >/dev/null 2>&1; then
	    python=$(find_python)
	    $pipenv --python $python
	else
	    $pipenv $PIPENV_OPTS
	fi
    fi

    # Lock dependencies (including development dependencies) and
    # generate Pipfile.lock
    $pipenv lock -d
}

refresh_virtualenv() (
    pipenv=$(get_python_utility pipenv || true)

    if [ -z "$pipenv" ]; then
	pip=$(get_python_utility pip || true)
    fi

    source_dir=$script_dir/..

    cd "$source_dir"

    if [ -n "$pipenv" ]; then
	refresh_via_pipenv
	generate_requirements_files $VENV_REQUIREMENTS
	$pipenv sync -d
    elif [ -n "$pip" ]; then
	pip_options="$(get_pip_options)"
	venv_force_sync=true
	venv_requirements=$VENV_REQUIREMENTS
	refresh_via_pip $VENV_FILENAME
    else
	abort "%s: Neither pip nor pipenv found in PATH\n" "$0"
    fi
)

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

if [ "$(id -u)" -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    abort "%s: Must not be run within a virtual environment\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"

refresh_virtualenv