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

PIP="pip3 -q"

abort() {
    printf "$@" >&2
    exit 1
}

create_venv() {
    (cd $source_dir

     if [ ! -d .venv ]; then
	 python3 -m venv .venv
     fi

     if [ -d .venv ]; then
	 . .venv/bin/activate
	 $PIP install --upgrade pip
	 $PIP install -r requirements.txt -r requirements-dev.txt
     fi)
}

run_venv() {
    if [ -d $source_dir/.venv ]; then
	printf "%s\n" "Activating virtual environment"
	. $source_dir/.venv/bin/activate
	printf "%s\n" "Loading .env environment variables"
	. $source_dir/.env
	export DATABASE_DIALECT DATABASE_HOST DATABASE_PASSWORD DATABASE_USER
	export FLASK_APP FLASK_ENV
	"$@"
    else
	abort "%s\n" "No available virtualenv"
    fi
}

pipenv=$(which pipenv 2>/dev/null || true)
source_dir=$(dirname $0)/..

if [ -n "$pipenv" ]; then
    venv="$($pipenv --bare --venv 2>/dev/null || true)"

    if [ -z "$venv" ]; then
	$pipenv update
    fi
else
    create_venv
fi

if [ -n "$pipenv" ]; then
    $pipenv run "$@"
else
    run_venv "$@"
fi
