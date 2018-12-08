#!/bin/sh -eu

# get-database-server-packages: get database server package names
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

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

package="$($script_dir/get-database-server-package.sh)"

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		packages="$DEBIAN_PKG"
		;;
	    (fedora)
		packages="$FEDORA_PKG"
		;;
	    (redhat|centos)
		packages="${package:-$REDHAT_PKG}"
		;;
	    (opensuse-*)
		packages="${package:-$OPENSUSE_PKG}"
		;;
	    (ubuntu)
		packages="$UBUNTU_PKG"
		;;
	esac
	;;
    (FreeBSD)
	packages="${package:-$FREEBSD_PKG}"
	;;
    (SunOS)
	packages="${package:-$SUNOS_PKG}"
	;;
esac

printf "%s\n" $packages
