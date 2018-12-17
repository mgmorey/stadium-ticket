#!/bin/sh -eu

# get-uwsgi-packages: get uWSGI app server package names
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

DARWIN_PKGS="uwsgi"

DEBIAN_PKGS="uwsgi uwsgi-plugin-%s"

FEDORA_PKGS="uwsgi uwsgi-plugin-%s"

FREEBSD_PKGS="uwsgi-%s"

OPENSUSE_PKGS="uwsgi uwsgi-python3"

REDHAT_PKGS="uwsgi uwsgi-plugin-%s"

SUNOS_PKGS=""

UBUNTU_PKGS="uwsgi uwsgi-plugin-%s"

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
distro_name=$($script_dir/get-os-distro-name.sh)
kernel_name=$($script_dir/get-os-kernel-name.sh)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		packages="$DEBIAN_PKGS"
		;;
	    (fedora)
		packages="$FEDORA_PKGS"
		;;
	    (redhat|centos)
		packages="$REDHAT_PKGS"
		;;
	    (opensuse-*)
		packages="$OPENSUSE_PKGS"
		;;
	    (ubuntu)
		packages="$UBUNTU_PKGS"
		;;
	esac
	;;
    (Darwin)
	packages="$DARWIN_PKGS"
	;;
    (FreeBSD)
	packages="$FREEBSD_PKGS"
	;;
    (SunOS)
	packages="$SUNOS_PKGS"
	;;
esac

python_info=$($script_dir/get-python-package.sh)
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
