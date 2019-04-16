#!/bin/sh -eu

# get-docker-client-packages: get Docker client package names
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

DEBIAN_PKG="docker"
DEBIAN_PKGS="docker-compose"

FEDORA_PKG="docker"
FEDORA_PKGS="docker-compose"

FREEBSD_PKG="docker"
FREEBSD_PKGS="docker-compose-%s"

OPENSUSE_PKG="docker"
OPENSUSE_PKGS="docker-compose"

REDHAT_PKG="docker-client"
REDHAT_PKGS="docker-compose"

SUNOS_PKG=""
SUNOS_PKGS=""

UBUNTU_PKG="docker.io"
UBUNTU_PKGS="docker-compose docker-doc"

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

distro_name=$(sh -eu $script_dir/get-os-release.sh -i)
kernel_name=$(sh -eu $script_dir/get-os-kernel-name.sh)
pretty_name=$(sh -eu $script_dir/get-os-release.sh -p)

package=$(sh -eu $script_dir/get-docker-client-package.sh)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		packages="${package:-$DEBIAN_PKG} $DEBIAN_PKGS"
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

data=$(sh -eu $script_dir/get-python-package.sh)
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

printf "%s\n" $package_name

for package in ${packages:-}; do
    case $package in
	(*%s*)
	    printf "$package\n" $package_modifier
	    ;;
	(*)
	    printf "%s\n" $package
	    ;;
    esac
done
