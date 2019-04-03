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

PYTHON=python3
PIP_VENV=.venv
REQUIREMENTS="requirements-dev.txt requirements.txt"

abort() {
    printf "$@" >&2
    exit 1
}

activate_venv() {
    printf "%s\n" "Activating virtual environment"
    assert [ -r "$1/bin/activate" ]
    set +u
    . "$1/bin/activate"
    set -u
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

pip_run() {
    if [ ! -d $PIP_VENV ]; then
	$script_dir/create-virtualenv.sh $PIP_VENV
	populate=true
    else
	populate=false
    fi

    if [ -r $PIP_VENV/bin/activate ]; then
	activate_venv $PIP_VENV

	if [ "$populate" = true ]; then
	    . $script_dir/sync-virtualenv.sh
	fi

	printf "%s\n" "Loading .env environment variables"
	. ./.env
	export DATABASE_DIALECT DATABASE_HOST DATABASE_PASSWORD
	export DATABASE_PORT DATABASE_SCHEMA DATABASE_USER
	export FLASK_APP FLASK_ENV
	"$@"
    elif [ -d $PIP_VENV ]; then
	abort "%s\n" "Unable to activate environment"
    else
	abort "%s\n" "No virtual environment"
    fi
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

script_dir=$(realpath "$(dirname "$0")")
source_dir=$script_dir/..

cd $source_dir

for pipenv in pipenv "$PYTHON -m pipenv" false; do
    if $pipenv >/dev/null 2>&1; then
	break
    fi
done

if [ "$pipenv" != false ]; then
    pipenv_run "$@"
else
    pip_run "$@"
fi
