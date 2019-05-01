#!/bin/sh -eu

# get-docker-packages: get Docker package names
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

DARWIN_PKG="docker"
DARWIN_PKGS="docker-compose"

DEBIAN_9_PKG="docker"
DEBIAN_10_PKG="docker.io"
DEBIAN_PKGS="docker-compose"

FEDORA_PKG="docker"
FEDORA_PKGS="docker-compose"

FREEBSD_PKG="docker"
FREEBSD_PKGS="docker-compose-%s"

OPENSUSE_PKG="docker"
OPENSUSE_PKGS="%s-docker-compose"

REDHAT_PKG="docker"
REDHAT_PKGS="docker-compose"

SUNOS_PKG=""
SUNOS_PKGS=""

UBUNTU_PKG="docker.io"
UBUNTU_PKGS="docker-compose"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

script_dir=$(get_path "$(dirname "$0")")

package=$($script_dir/get-docker-package.sh)

eval $($script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (debian)
		case "$VERSION_ID" in
		    (9)
			packages="${package:-$DEBIAN_9_PKG} $DEBIAN_PKGS"
			;;
		    (10)
			packages="${package:-$DEBIAN_10_PKG} $DEBIAN_PKGS"
			;;
		esac
		;;
	    (fedora)
		packages="${package:-$FEDORA_PKG} $FEDORA_PKGS"
		;;
	    (redhat|centos)
		packages="${package:-$REDHAT_PKG} $REDHAT_PKGS"
		;;
	    (opensuse-*)
		packages="${package:-$OPENSUSE_PKG} $OPENSUSE_PKGS"
		;;
	    (ubuntu)
		packages="${package:-$UBUNTU_PKG} $UBUNTU_PKGS"
		;;
	esac
	;;
    (Darwin)
	packages="${package:-$DARWIN_PKG} $DARWIN_PKGS"
	;;
    (FreeBSD)
	packages="${package:-$FREEBSD_PKG} $FREEBSD_PKGS"
	;;
    (SunOS)
	packages="${package:-$SUNOS_PKG}"
	;;
esac

if [ -n "${packages-}" ]; then
    $script_dir/get-python-packages.sh $packages
fi
