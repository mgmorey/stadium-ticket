#!/bin/sh -eu

# get-mysql-client-packages: get MySQL-client-packages
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

CENTOS_PKGS="mariadb"

DEBIAN_PKGS="mariadb-client-10.1 python3-pymysql python3-sqlalchemy"

FEDORA_PKGS="mariadb python3-PyMySQL python3-sqlalchemy"

FREEBSD_PKGS="mysql56-client py36-pymysql py36-sqlalchemy12"

OPENSUSE_PKGS="mariadb python3-PyMySQL python3-SQLAlchemy"

SUNOS_PKGS="mariadb-101 sqlalchemy-34"

UBUNTU_PKGS="mariadb-client-10.1 python3-pymysql python3-sqlalchemy"

abort() {
    printf "$@" >&2
    exit 1
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (centos)
		printf "%s\n" $CENTOS_PKGS
		;;
	    (debian)
		printf "%s\n" $DEBIAN_PKGS
		;;
	    (fedora)
		printf "%s\n" $FEDORA_PKGS
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
