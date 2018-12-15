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

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

if [ $(id -u) -eq 0 ]; then
    exit 0
fi

cd $source_dir

pip=$(which $PIP)
$pip install --upgrade --user pip

pip=$(which $PIP)
$pip install -r requirements.txt -r requirements-dev.txt --user
