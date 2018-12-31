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

DEBIAN_PKGS="%s-flask %s-flask-restful %s-flask-sqlalchemy"

FEDORA_PKGS="%s-flask %s-flask-restful %s-flask-sqlalchemy"

FREEBSD_PKGS="%s-Flask %s-Flask-RESTful %s-Flask-SQLAlchemy"

OPENSUSE_PKGS="%s-Flask %s-Flask-RESTful %s-Flask-SQLAlchemy"

REDHAT_PKGS=""

SUNOS_PKGS=""

UBUNTU_PKGS="%s-flask %s-flask-restful %s-flask-sqlalchemy"

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

script_dir=$(realpath $(dirname $0))
kernel_name=$(sh -eu "$script_dir/get-os-kernel-name.sh")

case "$kernel_name" in
    (Linux)
	distro_name=$(sh -eu "$script_dir/get-os-distro-name.sh")

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

data=$(sh -eu "$script_dir/get-python-package.sh")
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

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
