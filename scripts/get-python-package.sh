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

DARWIN_INFO=":python37 py37"

DEBIAN_INFO="python3 python3"

FEDORA_INFO="python36 python3"

FREEBSD_INFO="python3 py36"

NETBSD_INFO="python37 py37"

OPENSUSE_INFO="python3 python3"

REDHAT_8_INFO="python3 python3"

SUNOS_INFO=":python37 py37"

UBUNTU_INFO="python3 python3"

abort() {
    printf "$@" >&2
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_python_package() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    printf "%s %s\n" $DEBIAN_INFO
		    ;;
		(ubuntu)
		    printf "%s %s\n" $UBUNTU_INFO
		    ;;
		(opensuse-*)
		    printf "%s %s\n" $OPENSUSE_INFO
		    ;;
		(fedora)
		    printf "%s %s\n" $FEDORA_INFO
		    ;;
		(redhat|centos|ol)
		    case "$VERSION_ID" in
			(8|8.0)
			    printf "%s %s\n" $REDHAT_8_INFO
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    printf "%s %s\n" $DARWIN_INFO
	    ;;
	(FreeBSD)
	    printf "%s %s\n" $FREEBSD_INFO
	    ;;
	(NetBSD)
	    printf "%s %s\n" $NETBSD_INFO
	    ;;
	(SunOS)
	    printf "%s %s\n" $SUNOS_INFO
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_python_package
