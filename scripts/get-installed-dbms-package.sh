#!/bin/sh -eu

# get-installed-dbms-package: get installed database package name
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

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

if [ $# -ne 1 ]; then
    abort "%s: Invalid number of arguments\n" "$0"
elif [ "$1" != client -a "$1" != server ]; then
    abort "%s: Invalid argument -- %s\n" "$0" "$1"
fi

mode=$1
script_dir=$(get_path "$(dirname "$0")")

tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

"$script_dir/get-installed-packages.sh" >$tmpfile
"$script_dir/grep-dbms-package.sh" $mode-core <$tmpfile || \
    "$script_dir/grep-dbms-package.sh" $mode <$tmpfile || \
    "$script_dir/grep-dbms-package.sh" <$tmpfile || \
    true
