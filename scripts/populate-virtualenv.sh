#!/bin/sh -eu

# populate-virtualenv: install requirements into virtual environment
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

# Use no cache if child process of sudo
pip_opts=${SUDO_USER:+--no-cache-dir}

printf "%s\n" "Upgrading pip"
pip="$(which $PYTHON) -m pip $pip_opts"
$pip install --upgrade pip
pip="$(which $PIP) $pip_opts"
printf "%s\n" "Installing required packages"
$pip install $(printf -- "-r %s\n" requirements*.txt)
