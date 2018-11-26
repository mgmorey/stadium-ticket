#!/bin/sh -eu

# get-mysql-server-packages: get MySQL server package names
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

DEBIAN_PKGS="mariadb-server-10.1"

FEDORA_PKGS="mariadb-server"

FREEBSD_PKGS="mariadb101-server"

OPENSUSE_PKGS="mariadb"

REDHAT_PKGS="mariadb-server"

SUNOS_PKGS="mariadb-101"

UBUNTU_PKGS="mariadb-server-10.1"

abort() {
    printf "$@" >&2
    exit 1
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		printf "%s\n" $DEBIAN_PKGS
		;;
	    (fedora)
		printf "%s\n" $FEDORA_PKGS
		;;
	    (redhat|centos)
		printf "%s\n" $REDHAT_PKGS
		;;
	    (opensuse-*)
		printf "%s\n" $OPENSUSE_PKGS
		;;
	    (ubuntu)
		printf "%s\n" $UBUNTU_PKGS
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (FreeBSD)
	printf "%s\n" $FREEBSD_PKGS
	;;
    (SunOS)
	printf "%s\n" $SUNOS_PKGS
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
