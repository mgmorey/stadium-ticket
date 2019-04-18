#!/bin/sh -eu

# get-dependencies: get list of prerequisites for developing app
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

CATEGORIES="dbms-client dbms-server docker-client http-client"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_packages() {
    for category in $CATEGORIES; do
	sh $script_dir/get-$category-packages.sh
    done
}

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

script_dir=$(realpath "$(dirname "$0")")

eval $(sh -eu $script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu|fedora|opensuse-*)
		;;
	    (*)
		abort "%s: Distro not supported\n" "$pretty_name"
		;;
	esac
	;;
    (Darwin|FreeBSD|SunOS)
	;;
    (*)
	abort "%s: Operating system not supported\n" "$pretty_name"
	;;
esac

get_packages | sort -u
