#!/bin/sh -eu

# install-prerequisites: install prerequisites
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

CENTOS_DBMS="mariadb"
CENTOS_PKGS="curl httpd-tools $CENTOS_DBMS"

DEBIAN_DBMS="mariadb-server python3-pymysql python3-sqlalchemy"
DEBIAN_PKGS="curl apache2-utils python3 python3-pip $DEBIAN_DBMS python3-flask"

FEDORA_DBMS="mariadb python3-PyMySQL python3-sqlalchemy"
FEDORA_PKGS="curl httpd-tools python3 python3-pip $FEDORA_DBMS python3-flask"

FREEBSD_DBMS="mysql56-server py36-pymysql py36-sqlalchemy12"
FREEBSD_PKGS="apache24 curl python3 py36-pip $FREEBSD_DBMS py36-Flask"

OPENSUSE_DBMS="mariadb python3-PyMySQL python3-SQLAlchemy"
OPENSUSE_PKGS="apache2-utils curl python3 python3-pip $OPENSUSE_DBMS python3-Flask"

SUNOS_DBMS="mariadb-101 sqlalchemy-34"
SUNOS_PKGS="apache-24 curl python-34 pip-34 $SUNOS_DBMS"

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
	    (debian|ubuntu)
		printf "%s\n" $DEBIAN_PKGS
		;;
	    (fedora)
		printf "%s\n" $FEDORA_PKGS
		;;
	    (opensuse-*)
		printf "%s\n" $OPENSUSE_PKGS
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
