#!/bin/sh -eu

# get-middleware-packages: get middleware package names
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

DEBIAN_PKGS="build-essential libffi-dev libssl-dev %s-dev %s-flask \
%s-flask-restful %s-flask-sqlalchemy %s-pip %s-pytest"

FEDORA_PKGS="gcc libffi-devel openssl-devel %s-devel %s-flask \
%s-flask-restful %s-flask-sqlalchemy %s-pip %s-pytest"

FREEBSD_PKGS="openssl-devel %s-Flask %s-Flask-RESTful \
%s-Flask-SQLAlchemy %s-pip %s-pytest"

OPENSUSE_PKGS="gcc libffi-devel libressl-devel %s-devel %s-Flask \
%s-Flask-RESTful %s-Flask-SQLAlchemy %s-pip %s-pytest"

REDHAT_PKGS="gcc libffi-devel openssl-devel %s-devel %s-pip %s-PyMySQL \
%s-pytest sclo-%s-python-flask"

SUNOS_PKGS="build-essential pip-%s pytest-%s"

UBUNTU_PKGS="build-essential libffi-dev libssl-dev %s-dev %s-flask \
%s-flask-restful %s-flask-sqlalchemy %s-pip %s-pytest"

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		packages=$DEBIAN_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (redhat|centos)
		packages=$REDHAT_PKGS
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

data=$($script_dir/get-python-package.sh)
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

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
