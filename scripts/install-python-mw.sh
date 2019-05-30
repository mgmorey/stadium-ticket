#!/bin/sh -eu

# install-python-mw: install Python middleware packages
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

install_python_mw() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian)
		    case "$VERSION_ID" in
			(9)
			    :
			    ;;
			(10)
			    :
			    ;;
			('')
			    case "$(cat /etc/debian_version)" in
				(buster/sid)
				    :
				    ;;
				(*)
				    abort_not_supported Release
				    ;;
			    esac
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ubuntu)
		    case "$VERSION_ID" in
			(18.04)
			    :
			    ;;
			(19.04)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-*)
		    :
		    ;;
		(fedora)
		    :
		    ;;
		(redhat)
		    :
		    ;;
		(centos)
		    "$script_dir/install-packages.sh" epel-release
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    :
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    packages=$("$script_dir/get-python-mw-packages.sh")
    "$script_dir/install-packages.sh" $packages
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_python_mw
