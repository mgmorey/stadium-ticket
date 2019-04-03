#!/bin/sh -eu

# get-python-package: get Python package name
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

DARWIN_INFO="python python"

DEBIAN_INFO="python3 python3"

FEDORA_INFO="python36 python3"

FREEBSD_INFO="python3 py36"

OPENSUSE_INFO="python3 python3"

REDHAT_INFO="python36 python36"

SUNOS_INFO="python-34 34"

UBUNTU_INFO="python3 python3"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

script_dir=$(realpath "$(dirname "$0")")
distro_name=$(sh -eu $script_dir/get-os-distro-name.sh)
kernel_name=$(sh -eu $script_dir/get-os-kernel-name.sh)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		printf "%s %s\n" $DEBIAN_INFO
		;;
	    (fedora)
		printf "%s %s\n" $FEDORA_INFO
		;;
	    (opensuse-*)
		printf "%s %s\n" $OPENSUSE_INFO
		;;
	    (redhat|centos)
		printf "%s %s\n" $REDHAT_INFO
		;;
	    (ubuntu)
		printf "%s %s\n" $UBUNTU_INFO
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (Darwin)
	printf "%s %s\n" $DARWIN_INFO
	;;
    (FreeBSD)
	printf "%s %s\n" $FREEBSD_INFO
	;;
    (SunOS)
	printf "%s %s\n" $SUNOS_INFO
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
