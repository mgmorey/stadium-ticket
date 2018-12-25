#!/bin/sh -u

# install-uwsgi-packages: install uWSGI engine packages
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

abort() {
    printf "$@" >&2
    exit 1
}

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
	    (debian|ubuntu|centos|fedora|readhat|opensuse-*)
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (Darwin|FreeBSD|SunOS)
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac

package_manager="$($script_dir/get-package-manager.sh)"

if [ -n "$package_manager" ]; then
    packages="$($script_dir/get-uwsgi-packages.sh)"

    if [ -n "$packages" ]; then
	$package_manager install $packages
    fi
fi
