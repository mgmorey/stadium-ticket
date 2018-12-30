#!/bin/sh -eu

# run: wrapper for running commands within a virtual environment
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

export LANG=${LANG:-C.UTF-8}
export LC_ALL=${LC_ALL:-C.UTF-8}

PIP=pip3
PYTHON=python3

abort() {
    printf "$@" >&2
    exit 1
}

pip_run() {
    if [ ! -d .venv ]; then
	printf "%s\n" "Creating virtual environment"
	$PYTHON -m venv .venv
    fi

    if [ -r .venv/bin/activate ]; then
	printf "%s\n" "Activating virtual environment"
	. .venv/bin/activate
	printf "%s\n" "Loading .env environment variables"
	. ./.env
	export DATABASE_DIALECT DATABASE_HOST DATABASE_PASSWORD
	export DATABASE_PORT DATABASE_SCHEMA DATABASE_USER
	export FLASK_APP FLASK_ENV
	"$@"
    elif [ -d .venv ]; then
	abort "%s\n" "Unable to activate environment"
    else
	abort "%s\n" "No virtual environment"
    fi
}

pipenv_run() {
    if [ ! "$pipenv" --bare --venv 2>/dev/null ]; then
	# if no virtualenv has been created yet, then
	# create it and install packages per Pipfile.lock
	$pipenv --bare install --ignore-pipfile
    elif [ $($pipenv graph | wc -c) -eq 0 ]; then
	# else if virtualenv contains no packages
	# intall packages per Pipfile.lock
	$pipenv --bare sync -d
    fi

    $pipenv run "$@"
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

pipenv=$(which pipenv 2>/dev/null || true)
script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "This script must be run as a non-privileged user"
fi

cd "$source_dir"

if [ -n "$pipenv" ]; then
    pipenv_run "$@"
else
    pip_run "$@"
fi
