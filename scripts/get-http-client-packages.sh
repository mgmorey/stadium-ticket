#!/bin/sh -eu

# get-http-client-packages: get HTTP client package names
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

DEBIAN_PKGS="apache2-utils curl"

FEDORA_PKGS="curl httpd-tools"

FREEBSD_PKGS="apache24 curl"

OPENSUSE_PKGS="apache2-utils curl"

REDHAT_PKGS="curl httpd-tools"

SUNOS_PKGS="apache-24 curl"

UBUNTU_PKGS="apache2-utils curl"

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux)
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


printf "%s\n" $packages
