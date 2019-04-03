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

abort() {
    printf "$@" >&2
    exit 1
}

PIP=pip3
PYTHON=python3

# Use no cache if child process of sudo
pip_opts=${SUDO_USER:+--no-cache-dir}

for pip in $PIP "$PYTHON -m pip" false; do
    if $pip >/dev/null 2>&1; then
	break
    fi
done

assert [ "$pip" != false ]
printf "%s\n" "Upgrading pip"
$pip install --upgrade pip
printf "%s\n" "Installing required packages"
$pip install $(printf -- "-r %s\n" ${REQUIREMENTS:-requirements.txt})

