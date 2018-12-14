#!/bin/sh -eu

# update-requirements: lock requirements and update virtualenv
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

PIP=pip3
PYTHON=python3

abort() {
    printf "$@" >&2
    exit 1
}

pip_update() (
    cd $source_dir

    if [ ! -d .venv ]; then
	printf "%s\n" "Creating virtual environment"
	$PYTHON -m venv .venv
    fi

    if [ -d .venv ]; then
	printf "%s\n" "Activating virtual environment"
	. .venv/bin/activate
	printf "%s\n" "Upgrading pip"
	pip="$(which $PYTHON) -m pip"
	$pip install --upgrade pip
	pip="$(which $PIP)"
	printf "%s\n" "Installing required packages"
	$pip install -r requirements.txt -r requirements-dev.txt
    else
	abort "%s\n" "No virtual environment"
    fi
)

pipenv_update() {
    pipenv update -d
}

script_dir=$(dirname $0)
source_dir=$script_dir/..

if [ -n "$pipenv" ]; then
    pipenv_update
else
    pip_update
fi
