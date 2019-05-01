#!/bin/sh -eu

# get-sqlite-packages: get SQLite3 package names
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

DARWIN_PKGS="sqlite"

DEBIAN_PKGS="sqlite3"

FEDORA_PKGS="sqlite"

FREEBSD_PKGS="%s-sqlite3 sqlite3"

OPENSUSE_PKGS="sqlite3"

REDHAT_PKGS="sqlite"

SUNOS_PKGS="database/sqlite-3"

UBUNTU_PKGS="sqlite3"

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

script_dir=$(get_path "$(dirname "$0")")

eval $(sh -eu $script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (debian)
		packages=$DEBIAN_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (redhat|centos)
		packages=$REDHAT_PKGS
		;;
	    (opensuse-*)
		packages=$OPENSUSE_PKGS
		;;
	    (ubuntu)
		packages=$UBUNTU_PKGS
		;;
	esac
	;;
    (Darwin)
	packages=$DARWIN_PKGS
	;;
    (FreeBSD)
	packages=$FREEBSD_PKGS
	;;
    (SunOS)
	packages=$SUNOS_PKGS
	;;
esac

if [ "${packages-}" ]; then
    sh -eu $script_dir/get-python-packages.sh $packages
fi
