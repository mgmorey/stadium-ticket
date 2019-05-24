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

FREEBSD_PKGS="apache24 curl"

OPENSUSE_PKGS="apache2-utils curl"

REDHAT_PKGS="curl httpd-tools"

SUNOS_PKGS="apache-24 curl"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_http_client_packages() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian|ubuntu)
		    packages="$DEBIAN_PKGS"
		    ;;
		(opensuse-*)
		    packages="$OPENSUSE_PKGS"
		    ;;
		(fedora|redhat|centos)
		    packages="$REDHAT_PKGS"
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

    if [ -n "${packages:-}" ]; then
	printf "%s\n" $packages
    fi
}

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_http_client_packages
