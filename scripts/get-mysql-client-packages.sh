#!/bin/sh -eu

# get-mysql-client-packages: get MySQL database client package names
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

DEBIAN_10_PKG="mariadb-client-10.3"
DEBIAN_PKGS="%s-pymysql %s-sqlalchemy"

FEDORA_PKG="mariadb"
FEDORA_PKGS="%s-PyMySQL %s-sqlalchemy"

FREEBSD_PKG="mariadb103-client"
FREEBSD_PKGS="%s-pymysql %s-sqlalchemy12"

ILLUMOS_PKG="database/mariadb-101/client"
ILLUMOS_PKGS=":%s-pymysql :%s-sqlalchemy"

NETBSD_PKG="mariadb-client"
NETBSD_PKGS="%s-pymysql %s-sqlalchemy"

OPENSUSE_PKG="mariadb-client"
OPENSUSE_PKGS="%s-PyMySQL %s-SQLAlchemy"

REDHAT_PKG="mariadb"

SOLARIS_PKG="database/mysql-57/client"

UBUNTU_18_04_PKG="mariadb-client-10.1"
UBUNTU_19_10_PKG="mariadb-client-10.3"
UBUNTU_PKGS="%s-pymysql %s-sqlalchemy"

abort() {
    printf "$@" >&2
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_mysql_client_packages() {
    package=$("$script_dir/get-installed-mysql-package.sh" client)

    case "$package" in
	(*-client-core-*)
	    package=$(printf "%s\n" $package | sed -e 's/-core-/-/')
	    ;;
    esac

    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    case "$VERSION_ID" in
			(10)
			    packages="${package:-$DEBIAN_10_PKG} $DEBIAN_PKGS"
			    ;;
		    esac
		    ;;
		(ubuntu|neon)
		    case "$VERSION_ID" in
			(18.04)
			    packages="${package:-$UBUNTU_18_04_PKG} $UBUNTU_PKGS"
			    ;;
			(19.10)
			    packages="${package:-$UBUNTU_19_10_PKG} $UBUNTU_PKGS"
			    ;;
		    esac
		    ;;
		(linuxmint)
		    case "$VERSION_ID" in
			(19.2)
			    packages="${package:-$UBUNTU_18_04_PKG} $UBUNTU_PKGS"
			    ;;
		    esac
		    ;;
		(kali)
		    case "$VERSION_ID" in
			(2019.3)
			    packages="${package:-$DEBIAN_10_PKG} $DEBIAN_PKGS"
			    ;;
		    esac
		    ;;
		(opensuse-*)
		    packages="${package:-$OPENSUSE_PKG} $OPENSUSE_PKGS"
		    ;;
		(fedora)
		    packages="${package:-$FEDORA_PKG} $FEDORA_PKGS"
		    ;;
		(rhel|ol|centos)
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
	(NetBSD)
	    packages="${package:-$NETBSD_PKG} $NETBSD_PKGS"
	    ;;
	(SunOS)
	    case "$ID" in
		(illumos)
		    packages="${package:-$ILLUMOS_PKG} $ILLUMOS_PKGS"
		    ;;
		(solaris)
		    packages="${package:-$SOLARIS_PKG}"
		    ;;
	    esac
	    ;;
    esac

    "$bin_dir/get-python-packages" ${packages-}
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-functions.sh"

bin_dir="$(get_bin_directory "$script_dir")"
eval $("$bin_dir/get-os-release" -x)

get_mysql_client_packages