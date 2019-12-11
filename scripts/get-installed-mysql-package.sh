#!/bin/sh -eu

# get-installed-mysql-package: get installed database package name
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

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

if [ $# -ne 1 ]; then
    abort "%s: Invalid number of arguments\n" "$0"
elif [ "$1" != client -a "$1" != server ]; then
    abort "%s: Invalid argument -- %s\n" "$0" "$1"
fi

mode=$1
script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-functions.sh"

create_tmpfile
get-installed-packages >$tmpfile
"$script_dir/grep-mysql-package.sh" $mode-core <$tmpfile || \
    "$script_dir/grep-mysql-package.sh" $mode <$tmpfile || \
    "$script_dir/grep-mysql-package.sh" <$tmpfile || \
    true
