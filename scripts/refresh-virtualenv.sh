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
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    pipenv=$1
    shift
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
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    if ! $1 --venv >/dev/null 2>&1; then
	if upgrade_via_pip pip pipenv; then
	    if [ -n "${BASH:-}" -o -n "${ZSH_VERSION:-}" ] ; then
		hash -r
	    fi
	fi

	if pyenv --version >/dev/null 2>&1; then
	    $1 --python "$(find_python)"
	else
	    $1 $PIPENV_OPTS
	fi
    fi

    # Lock dependencies (including development dependencies) and
    # generate Pipfile.lock
    $1 lock -d
}

refresh_virtualenv() (
    configure_baseline
    source_dir=$script_dir/..
    cd "$source_dir"

    for utility in $PYPI_UTILITIES; do
	case "$utility" in
	    (pipenv)
		pipenv=$(get_command pipenv || true)

		if [ -z "$pipenv" ]; then
		    continue
		fi

		if refresh_via_pipenv $pipenv; then
		    if generate_requirements_files $pipenv $VENV_REQUIREMENTS; then
			if $pipenv sync -d; then
			    return 0
			fi
		    fi
		fi
		;;
	    (pip)
		venv_force_sync=true
		venv_requirements=$VENV_REQUIREMENTS

		if refresh_via_pip $VENV_FILENAME; then
		    return 0
		fi
		;;
	esac
    done
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
. "$script_dir/system-parameters.sh"

refresh_virtualenv
