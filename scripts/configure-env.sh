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

create_tmpfile() {
    tmpfile=$(mktemp)
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile ${tmpfile}~"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

if [ -z "${TERM-}" ]; then
    exit 0
elif [ $TERM = dumb ]; then
    exit 0
elif [ -z "${EDITOR}" ]; then
    exit 0
fi

if [ $# -eq 0 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ $# -gt 2 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

file="$1"
template="$2"
create_tmpfile

if $EDITOR $tmpfile; then
    if [ -r $file ]; then
	cp -f $file $tmpfile
    elif [ -r $template ]; then
	cp -f $template $tmpfile
    fi

    mv -f $tmpfile $file
    chgrp $(id -g) $file
fi
