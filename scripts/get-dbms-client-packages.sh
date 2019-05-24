#!/bin/sh -eu

# get-dbms-client-packages: get DBMS client package names
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

DEBIAN_9_PKG="mariadb-client-10.1"
DEBIAN_10_PKG="mariadb-client-10.3"
DEBIAN_PKGS="%s-pymysql %s-sqlalchemy"

FEDORA_PKG="mariadb"
FEDORA_PKGS="%s-PyMySQL %s-sqlalchemy"

FREEBSD_PKG="mariadb103-client"
FREEBSD_PKGS="%s-pymysql %s-sqlalchemy12"

OPENSUSE_PKG="mariadb-client"
OPENSUSE_PKGS="%s-PyMySQL %s-SQLAlchemy"

REDHAT_PKG="mariadb"

SUNOS_PKG="mariadb-103/client"
SUNOS_PKGS="sqlalchemy-%s"

UBUNTU_18_04_PKG="mariadb-client-10.1"
UBUNTU_19_04_PKG="mariadb-client-10.3"
UBUNTU_PKGS="%s-pymysql %s-sqlalchemy"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_dbms_client_packages() {
    package=$("$script_dir/get-installed-dbms-package.sh" client)

    case "$package" in
	(*-client-core-*)
	    package=$(printf "%s\n" $package | sed -e 's/-core-/-/')
	    ;;
    esac

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(9)
			    packages="${package:-$DEBIAN_9_PKG} $DEBIAN_PKGS"
			    ;;
			(10)
			    packages="${package:-$DEBIAN_10_PKG} $DEBIAN_PKGS"
			    ;;
			('')
			    case "$(cat /etc/debian_version)" in
				(buster/sid)
				    packages="${package:-$DEBIAN_10_PKG} $DEBIAN_PKGS"
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
			    packages="${package:-$UBUNTU_18_04_PKG} $UBUNTU_PKGS"
			    ;;
			(19.04)
			    packages="${package:-$UBUNTU_19_04_PKG} $UBUNTU_PKGS"
			    ;;
		    esac
		    ;;
		(opensuse-*)
		    packages="${package:-$OPENSUSE_PKG} $OPENSUSE_PKGS"
		    ;;
		(fedora)
		    packages="${package:-$FEDORA_PKG} $FEDORA_PKGS"
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
	    packages="${package:-$FREEBSD_PKG} $FREEBSD_PKGS"
	    ;;
	(SunOS)
	    packages="${package:-$SUNOS_PKG} $SUNOS_PKGS"
	    ;;
    esac

    "$script_dir/get-python-packages.sh" $packages
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

get_dbms_client_packages
