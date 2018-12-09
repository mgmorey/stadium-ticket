#!/bin/sh -eu

# get-sqlite-packages: get SQLite3 package names
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

DEBIAN_PKGS=""

FEDORA_PKGS=""

FREEBSD_PKGS=""

OPENSUSE_PKGS=""

REDHAT_PKGS=""

SUNOS_PKGS="sqlite-3"

UBUNTU_PKGS=""

abort() {
    printf "$@" >&2
    exit 1
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

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
    (FreeBSD)
	packages="$FREEBSD_PKGS"
	;;
    (SunOS)
	packages="$SUNOS_PKGS"
	;;
esac

if [ -n "$packages" ]; then
    printf "%s\n" $packages
fi
