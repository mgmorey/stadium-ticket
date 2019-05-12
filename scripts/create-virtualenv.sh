#!/bin/sh -eu

# create-virtualenv.sh: create application virtual environment
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

if [ $# -eq 0 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ $# -gt 1 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/virtualenv-functions.sh"

source_dir=$script_dir/..

cd "$source_dir"

pip=$("$script_dir/get-python-command.sh" pip)
pipenv=$("$script_dir/get-python-command.sh" pipenv)
python=
venv_filename=$1
venv_requirements=requirements.txt

case $venv_filename in
    ($VENV_FILENAME)
	;;
    ($VENV_FILENAME-$APP_NAME)
	python=$(find_system_python)
	;;
esac

sync_virtualenv $venv_filename $python
