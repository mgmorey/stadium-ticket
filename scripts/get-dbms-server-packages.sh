#!/bin/sh -eu

# get-dbms-server-packages: get database server package names
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

DARWIN_PKG="mariadb"

DEBIAN_PKG="mariadb-server-10.1"

FEDORA_PKG="mariadb-server"

FREEBSD_PKG="mariadb103-server"

OPENSUSE_PKG="mariadb"

REDHAT_PKG="mariadb-server"

SUNOS_PKG="mariadb-101"

UBUNTU_PKG="mariadb-server-10.1"

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

package=$(sh -eu $script_dir/get-dbms-server-package.sh)

eval $(sh -eu $script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (debian)
		packages="${package:-$DEBIAN_PKG}"
		;;
	    (fedora)
		packages="${package:-$FEDORA_PKG}"
		;;
	    (redhat|centos)
		packages="${package:-$REDHAT_PKG}"
		;;
	    (opensuse-*)
		packages="${package:-$OPENSUSE_PKG}"
		;;
	    (ubuntu)
		packages="${package:-$UBUNTU_PKG}"
		;;
	esac
	;;
    (Darwin)
	packages="${package:-$DARWIN_PKG}"
	;;
    (FreeBSD)
	packages="${package:-$FREEBSD_PKG}"
	;;
    (SunOS)
	packages="${package:-$SUNOS_PKG}"
	;;
esac

printf "%s\n" $packages
