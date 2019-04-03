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

export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

APP_VARS="DATABASE_DIALECT DATABASE_HOST DATABASE_PASSWORD DATABASE_PORT \
DATABASE_SCHEMA DATABASE_USER FLASK_APP FLASK_ENV"
PIP_VENV=.venv
PYTHON=python3
REQUIREMENTS="requirements-dev.txt requirements.txt"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

pip_run() {
    pip_venv=$PIP_VENV
    . $script_dir/deploy-virtualenv.sh
    printf "%s\n" "Loading .env environment variables"
    . ./.env

    for var in $APP_VARS; do
	export $var
    done

    "$@"
}

pipenv_run() {
    if ! $pipenv --venv >/dev/null 2>&1; then
	$pipenv sync -d
    fi

    if [ "${PIPENV_ACTIVE:-0}" -gt 0 ]; then
	"$@"
    else
	$pipenv run "$@"
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

for pipenv in pipenv "$PYTHON -m pipenv" false; do
    if $pipenv >/dev/null 2>&1; then
	break
    fi
done

script_dir=$(realpath "$(dirname "$0")")
source_dir=$script_dir/..

cd $source_dir

if [ "$pipenv" != false ]; then
    pipenv_run "$@"
else
    pip_run "$@"
fi
