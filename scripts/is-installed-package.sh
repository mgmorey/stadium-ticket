#!/bin/sh -eu

# installed-package: get name of installed package
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

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
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

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

script_dir=$(get_path "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (ubuntu)
		status=$(dpkg-query -Wf '${Status}\n' $1 2>/dev/null)
		test "$status" = "install ok installed"
	    	;;
	    (opensuse-*)
		rpm --query $1 >/dev/null 2>&1
		;;
	    (*)
		abort_not_supported Distro
		;;
	esac
	;;
    (Darwin)
	test -x /usr/bin/uwsgi -o -x /usr/local/bin/uwsgi
    	;;
    # (FreeBSD)
    # 	;;
    # (SunOS)
    # 	;;
    (*)
	abort_not_supported "Operating system"
	;;
esac
