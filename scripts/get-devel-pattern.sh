#!/bin/sh -eu

# get-devel-pattern: get essential build/development pattern
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

DARWIN_PATT=""

DEBIAN_PATT="build-essential"

FEDORA_PATT=""

FREEBSD_PATT=""

OPENSUSE_PATT="devel_basis"

REDHAT_PATT=""

SUNOS_PATT="build-essential"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_devel_pattern() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian|ubuntu)
		    pattern=$DEBIAN_PATT
		    ;;
		(opensuse-*)
		    pattern=$OPENSUSE_PATT
		    ;;
		(fedora)
		    pattern=$FEDORA_PATT
		    ;;
		(redhat|centos)
		    pattern=$REDHAT_PATT
		    ;;
	    esac
	    ;;
	(Darwin)
	    pattern=$DARWIN_PATT
	    ;;
	(FreeBSD)
	    pattern=$FREEBSD_PATT
	    ;;
	(SunOS)
	    pattern=$SUNOS_PATT
	    ;;
    esac

    if [ -n "${pattern-}" ]; then
	printf "%s\n" $pattern
    fi
}

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_devel_pattern
