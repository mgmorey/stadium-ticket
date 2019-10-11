#!/bin/sh -eu

# get-package-managers: get names of package manager utilities
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

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_package_manager() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu|linuxmint|neon|kali)
		    printf "%s\n" apt-get
		    ;;
		(opensuse-*)
		    printf "%s\n" zypper
		    ;;
		(fedora)
		    printf "%s\n" dnf
		    ;;
		(ol|centos)
		    case "$VERSION_ID" in
			(7|7.*)
			    printf "%s\n" yum /usr/pkg/bin/pkgin
			    ;;
			(8|8.*)
			    printf "%s\n" dnf
			    ;;
		    esac
		    ;;
	    esac
	    ;;
	(Darwin)
	    printf "%s\n" /usr/local/bin/brew /opt/pkg/bin/pkgin
	    ;;
	(FreeBSD)
	    printf "%s\n" pkg
	    ;;
	(NetBSD)
	    printf "%s\n" pkgin
	    ;;
	(SunOS)
	    printf "%s\n" pkg pkgin
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

get_package_manager