#!/bin/sh -eu

# get-package-list-command: get command to list installed packages
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

DEBIAN_CMD=""

FEDORA_CMD=""

FREEBSD_CMD="pkg info"

OPENSUSE_CMD=""

REDHAT_CMD=""

SUNOS_CMD=""

UBUNTU_CMD=""

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
		command=$DEBIAN_CMD
		;;
	    (fedora)
		command=$FEDORA_CMD
		;;
	    (redhat|centos)
		command=$REDHAT_CMD
		;;
	    (opensuse-*)
		command=$OPENSUSE_CMD
		;;
	    (ubuntu)
		command=$UBUNTU_CMD
		;;
	esac
	;;
    (FreeBSD)
	command=$FREEBSD_CMD
	;;
    (SunOS)
	command=$SUNOS_CMD
	;;
esac

if [ -n "$command" ]; then
    printf "%s\n" "$command"
fi
