#!/bin/sh -eu

# create-virtualenv.sh: create virtual environment via pip
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

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

create_virtualenv_via_pip() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    pip=$(get_python_command pip)
    pipenv=$(get_python_command pipenv)
    python=
    source_dir=$script_dir/..
    venv_filename=$1
    venv_requirements=requirements.txt

    cd "$source_dir"
    case $venv_filename in
	($VENV_FILENAME)
	    :
	    ;;
	($VENV_FILENAME-$APP_NAME)
	    python=${2-}
	    ;;
    esac

    sync_virtualenv_via_pip $venv_filename $python
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

if [ $# -eq 0 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ $# -gt 2 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-functions.sh"

set_unpriv_environment
create_virtualenv_via_pip "$@"
