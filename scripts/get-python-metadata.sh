#!/bin/sh -eu

# get-python-metadata: get Python package name and prefix
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

DARWIN_DATA=":python36 py36"

DEBIAN_DATA="python3 python3"

FEDORA_DATA="python3 python3"

FREEBSD_DATA="python3 py36"

ILLUMOS_DATA=":python36 py36"

NETBSD_DATA="python36 py36"

OPENSUSE_DATA="python3 python3"

REDHAT_7_DATA=":python37 py37"
REDHAT_8_DATA="python3 python3"

SOLARIS_DATA="runtime/python-35 35"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_python_metadata() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (debian)
		data="$DEBIAN_DATA"
		;;
	    (fedora)
		data="$FEDORA_DATA"
		;;
	    (opensuse)
		data="$OPENSUSE_DATA"
		;;
	    (rhel|ol|centos)
		case "$VERSION_ID" in
		    (7|7.*)
			data="$REDHAT_7_DATA"
			;;
		    (8|8.*)
			data="$REDHAT_8_DATA"
			;;
		esac
		;;
	    (darwin)
		data="$DARWIN_DATA"
		;;
	    (freebsd)
		data="$FREEBSD_DATA"
		;;
	    (netbsd)
		data="$NETBSD_DATA"
		;;
	    (illumos)
		data="$ILLUMOS_DATA"
		;;
	    (solaris)
		data="$SOLARIS_DATA"
		;;
	esac

	if [ -n "${data-}" ]; then
	    break
	fi
    done

    if [ -n "${data-}" ]; then
	printf "%s %s\n" "$data"
    fi
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

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -x)

get_python_metadata
