#!/bin/sh -eu

# get-uninstalled-packages: filter installed packages from list
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

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
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

get_uninstalled_packages() {
    create_tmpfile
    "$script_dir/get-installed-packages.sh" >$tmpfile

    for package; do
	if ! grep -Eq "^$package([0-9]*|-[0-9\.]+)?(nb[0-9]+)?\$" $tmpfile; then
	   printf "%s\n" "$package"
	fi
    done
}

script_dir=$(get_realpath "$(dirname "$0")")

get_uninstalled_packages "$@"
