#!/bin/sh -eu

# get-base-packages: get base package names
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

CENTOS_BASE_PKGS="curl httpd-tools %s"
CENTOS_PY_PKGS="%s-devel %s-pip %s-pytest sclo-%s-python-flask"

DEBIAN_BASE_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev %s"
DEBIAN_PY_PKGS="%s-dev %s-flask %s-pip %s-pytest"

FEDORA_BASE_PKGS="curl httpd-tools %s"
FEDORA_PY_PKGS="%s-flask %s-pip"

FREEBSD_BASE_PKGS="apache24 curl python3"
FREEBSD_PY_PKGS="%s-Flask %s-pip"

OPENSUSE_BASE_PKGS="apache2-utils curl %s"
OPENSUSE_PY_PKGS="%s-flask %s-pip %s-pytest"

SUNOS_PKGS="apache-24 curl python-34"
SUNOS_PY_PKGS="pip-34"

UBUNTU_BASE_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev %s"
UBUNTU_PY_PKGS="%s-dev %s-flask %s-pip %s-pytest"

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (centos)
		base_packages=$CENTOS_BASE_PKGS
		python_packages=$CENTOS_PY_PKGS
		;;
	    (debian)
		base_packages=$DEBIAN_BASE_PKGS
		python_packages=$DEBIAN_PY_PKGS
		;;
	    (fedora)
		base_packages=$FEDORA_BASE_PKGS
		python_packages=$FEDORA_PY_PKGS
		;;
	    (opensuse-*)
		base_packages=$OPENSUSE_BASE_PKGS
		python_packages=$OPENSUSE_PY_PKGS
		;;
	    (ubuntu)
		base_packages=$UBUNTU_BASE_PKGS
		python_packages=$UBUNTU_PY_PKGS
		;;
	esac
	;;
    (FreeBSD)
	printf "%s\n" $FREEBSD_PKGS
	;;
    (SunOS)
	printf "%s\n" $SUNOS_PKGS
	;;
esac

python_info=$($script_dir/get-python-package-info.sh)
package_name=$(printf "%s" "$python_info" | awk '{print $1}')
package_prefix=$(printf "%s" "$python_info" | awk '{print $2}')

for package in $base_packages; do
    printf "$package\n" $package_name
done
for package in $python_packages; do
    printf "$package\n" $package_prefix
done
