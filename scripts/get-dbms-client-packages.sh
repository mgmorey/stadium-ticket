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

DEBIAN_PKG="mariadb-client-10.1"
DEBIAN_PKGS="%s-pymysql %s-sqlalchemy"

FEDORA_PKG="mariadb"
FEDORA_PKGS="%s-PyMySQL %s-sqlalchemy"

FREEBSD_PKG="mariadb103-client"
FREEBSD_PKGS="%s-pymysql %s-sqlalchemy12"

OPENSUSE_PKG="mariadb-client"
OPENSUSE_PKGS="%s-PyMySQL %s-SQLAlchemy"

REDHAT_PKG="mariadb"
REDHAT_PKGS=""

SUNOS_PKG="mariadb-101/client"
SUNOS_PKGS="sqlalchemy-%s"

UBUNTU_PKG="mariadb-client-10.1"
UBUNTU_PKGS="%s-pymysql %s-sqlalchemy"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(realpath $(dirname $0))

package="$($script_dir/get-dbms-client-package.sh)"

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		packages="${package:-$DEBIAN_PKG} $DEBIAN_PKGS"
		;;
	    (fedora)
		packages="${package:-$FEDORA_PKG} $FEDORA_PKGS"
		;;
	    (redhat|centos)
		packages="${package:-$REDHAT_PKG} $REDHAT_PKGS"
		;;
	    (opensuse-*)
		packages="${package:-$OPENSUSE_PKG} $OPENSUSE_PKGS"
		;;
	    (ubuntu)
		packages="${package:-$UBUNTU_PKG} $UBUNTU_PKGS"
		;;
	esac
	;;
    (FreeBSD)
	packages="${package:-$FREEBSD_PKG} $FREEBSD_PKGS"
	;;
    (SunOS)
	packages="${package:-$SUNOS_PKG} $SUNOS_PKGS"
	;;
esac

python_info=$($script_dir/get-python-package.sh)
package_name=$(printf "%s" "$python_info" | awk '{print $1}')
package_modifier=$(printf "%s" "$python_info" | awk '{print $2}')

printf "%s\n" $package_name

for package in ${packages:-}; do
    case $package in
	(*%s*)
	    printf "$package\n" $package_modifier
	    ;;
	(*)
	    printf "%s\n" $package
	    ;;
    esac
done
