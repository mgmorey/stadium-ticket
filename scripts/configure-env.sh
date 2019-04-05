#!/bin/sh -eu

# configure-env: open application environment in a text editor
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

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile ${tmpfile}~" EXIT INT QUIT TERM

file="$1"

if [ -r $file ]; then
    cp -f $file $tmpfile
elif [ -r .env-template ]; then
    cp -f .env-template $tmpfile
fi

if ${EDITOR:=cat} $tmpfile; then
    mv -f $tmpfile $file
    chgrp $(id -g) $file
fi
