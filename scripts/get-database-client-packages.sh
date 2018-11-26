#!/bin/sh -eu

# get-database-client-packages: get DBMS client package names
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

CENTOS_PKGS="mariadb %s-sqlalchemy"

DEBIAN_PKGS="mariadb-client-10.1 python3-pymysql"

FEDORA_PKGS="mariadb python3-PyMySQL python3-sqlalchemy"

FREEBSD_PKGS="mariadb101-client %s-pymysql %s-sqlalchemy12"

OPENSUSE_PKGS="mariadb-client %s-PyMySQL %s-SQLAlchemy"

SUNOS_PKGS="mariadb-101/client sqlalchemy-%s"

UBUNTU_PKGS="mariadb-client-10.1 %s-pymysql %s-sqlalchemy"

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (centos)
		packages=$CENTOS_PKGS
		;;
	    (debian)
		packages=$DEBIAN_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (opensuse-*)
		packages=$OPENSUSE_PKGS
		;;
	    (ubuntu)
		packages=$UBUNTU_PKGS
		;;
	esac
	;;
    (FreeBSD)
	packages=$FREEBSD_PKGS
	;;
    (SunOS)
	packages=$SUNOS_PKGS
	;;
esac

python_info=$($script_dir/get-python-package-info.sh)
package_name=$(printf "%s" "$python_info" | awk '{print $1}')
package_modifier=$(printf "%s" "$python_info" | awk '{print $2}')

printf "%s\n" $package_name

for package in $packages; do
    case $package in
	(*%s*)
	    printf "$package\n" $package_modifier
	    ;;
	(*)
	    printf "%s\n" $package
	    ;;
    esac
done
