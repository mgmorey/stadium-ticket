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

CENTOS_PKGS="curl httpd-tools %s-devel %s-pip %s-pytest sclo-%s-python-flask"

DEBIAN_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev %s-dev %s-flask %s-pip %s-pytest"

FEDORA_PKGS="curl httpd-tools %s-flask %s-pip"

FREEBSD_PKGS="apache24 curl python3 %s-Flask %s-pip"

OPENSUSE_PKGS="apache2-utils curl %s-flask %s-pip %s-pytest"

SUNOS_PKGS="apache-24 curl pip-%s"

UBUNTU_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev %s-dev %s-flask %s-pip %s-pytest"

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
