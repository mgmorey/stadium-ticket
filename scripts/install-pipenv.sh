#!/bin/sh -eu

# install-pipenv: install Python 3 Version Management
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

PIP=pip3

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
distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

data=$($script_dir/get-python-package.sh)
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

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
    (FreeBSD)
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac

if [ $(id -u) -eq 0 ]; then
    exit 0
fi

pip=$(which $PIP)
$pip install --upgrade --user pip

pip=$(which $PIP)
$pip install --user pipenv
