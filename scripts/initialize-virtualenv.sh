#!/bin/sh -eu

# initialize-virtualenv: activate virtual environment and install requirements
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

# set default locales
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

printf "%s\n" "Activating virtual environment"
. ${virtualenv:-.venv}/bin/activate
printf "%s\n" "Upgrading pip"
pip="$(which $PYTHON) -m pip"
$pip install --upgrade pip
pip="$(which $PIP)"
printf "%s\n" "Installing required packages"
$pip install $(printf -- "-r %s\n" requirements*.txt)
