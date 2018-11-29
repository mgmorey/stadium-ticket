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

DEBIAN_INFO="python3 python3"

FEDORA_INFO="python36 python3"

FREEBSD_INFO="python3 py36"

OPENSUSE_INFO="python3 python3"

REDHAT_INFO="python34 python34"

SUNOS_INFO="python-34 34"

UBUNTU_INFO="python3 python3"

abort() {
    printf "$@" >&2
    exit 1
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

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
