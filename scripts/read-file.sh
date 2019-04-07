#!/bin/sh -eu

# read-file: print contents of a text file to standard output
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

if [ -r $1 ]; then
    cat $1
elif [ -e $1 ]; then
    abort "No permission to read file: %s\n" $1
fi
