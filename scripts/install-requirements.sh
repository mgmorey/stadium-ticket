#!/bin/sh -eu

# install-requirements: use PIP to install requirements
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

script_dir=$(dirname $0)
source_dir=$script_dir/..

if which $PIP >/dev/null 2>&1; then
    pip=$PIP
elif which $PYTHON >/dev/null 2>&1; then
    pip="$PYTHON -m pip"
else
    abort "PIP command unavailable"
fi

$pip install -r $source_dir/requirements.txt --user
$pip install -r $source_dir/requirements-dev.txt --user
