#!/bin/sh -eu

# get-os-release-name: print name of OS distribution release
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

KEYS="os centos fedora redhat system"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
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

kernel_name=$(sh -eu $script_dir/get-os-kernel-name.sh)

case "$kernel_name" in
    (NT)
	uname -r
	;;
    (Darwin|FreeBSD|GNU)
	uname -r
	;;
    (Linux)
	for key in $KEYS; do
	    file=/etc/$key-release

	    if [ -r $file ]; then
		case ${file#/etc/} in
		    (os-release)
			(. $file && printf "%s\n" "$VERSION_ID")
			exit 0
			;;
		    (*-release)
			awk '{print $4}' $file
			exit 0
			;;
		esac
	    fi
	done

	if [ -x /usr/bin/lsb_release ]; then
	    /usr/bin/lsb_release -rs
	fi
	;;
    (SunOS)
	os_version="$(uname -v)"
	printf "%s\n" "${os_version#*-}"
	;;
esac
