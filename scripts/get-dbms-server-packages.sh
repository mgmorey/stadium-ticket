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

DEBIAN_9_PKG="mariadb-server-10.1"
DEBIAN_10_PKG="mariadb-server-10.3"

FEDORA_PKG="mariadb-server"

FREEBSD_PKG="mariadb103-server"

OPENSUSE_PKG="mariadb"

REDHAT_PKG="mariadb-server"

SUNOS_PKG="mariadb-103"

UBUNTU_18_04_PKG="mariadb-server-10.1"
UBUNTU_19_04_PKG="mariadb-server-10.3"

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

package=$("$script_dir/get-installed-dbms-package.sh" server)

case "$package" in
    (*-server-core-*)
	package=$(printf "%s\n" $package | sed -e 's/-core-/-/')
	;;
esac

eval $("$script_dir/get-os-release.sh" -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (debian)
		case "$VERSION_ID" in
		    (9)
			packages="${package:-$DEBIAN_9_PKG}"
			;;
		    (10)
			packages="${package:-$DEBIAN_10_PKG}"
			;;
		    ('')
			case "$(cat /etc/debian_version)" in
			    (buster/sid)
				packages="${package:-$DEBIAN_10_PKG}"
				;;
			    (*)
				abort_not_supported Release
				;;
			esac
			;;
		esac
		;;
	    (ubuntu)
		case "$VERSION_ID" in
		    (18.04)
			packages="${package:-$UBUNTU_18_04_PKG}"
			;;
		    (19.04)
			packages="${package:-$UBUNTU_19_04_PKG}"
			;;
		esac
		;;
	    (opensuse-*)
		packages="${package:-$OPENSUSE_PKG}"
		;;
	    (fedora)
		packages="${package:-$FEDORA_PKG}"
		;;
	    (redhat|centos)
		packages="${package:-$REDHAT_PKG}"
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

if [ -n "${packages-}" ]; then
    printf "%s\n" $packages
fi
