#!/bin/sh -eu

# get-httpd-python-packages: get HTTPD/Python packages
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

CENTOS_PKGS="curl httpd-tools"

DEBIAN_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev \
python3 python3-dev python3-flask python3-pip python3-pytest"

FEDORA_PKGS="curl httpd-tools python3 \
python3-flask python3-pip"

FREEBSD_PKGS="apache24 curl python3 \
py36-Flask py36-pip"

OPENSUSE_PKGS="apache2-utils curl python3 \
python3-flask python3-pip python3-pytest"

SUNOS_PKGS="apache-24 curl python-34 \
pip-34"

UBUNTU_PKGS="apache2-utils build-essential curl libffi-dev libssl-dev \
python3 python3-dev python3-flask python3-pip python3-pytest"

abort() {
    printf "$@" >&2
    exit 1
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (centos)
		printf "%s\n" $CENTOS_PKGS
		;;
	    (debian)
		printf "%s\n" $DEBIAN_PKGS
		;;
	    (fedora)
		printf "%s\n" $FEDORA_PKGS
		;;
	    (opensuse-*)
		printf "%s\n" $OPENSUSE_PKGS
		;;
	    (ubuntu)
		printf "%s\n" $UBUNTU_PKGS
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (FreeBSD)
	printf "%s\n" $FREEBSD_PKGS
	;;
    (SunOS)
	printf "%s\n" $SUNOS_PKGS
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
