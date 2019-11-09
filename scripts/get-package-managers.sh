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
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (debian)
		managers="apt-get"
		;;
	    (fedora)
		managers="dnf"
		;;
	    (opensuse)
		managers="zypper"
		;;
	    (rhel|ol|centos)
		case "$VERSION_ID" in
		    (7|7.[78])
			managers="yum /usr/pkg/bin/pkgin"
			;;
		    (8|8.[01])
			managers="dnf"
			;;
		esac
		;;
	    (macos)
		managers="/usr/local/bin/brew /opt/pkg/bin/pkgin"
		;;
	    (freebsd)
		managers="pkg"
		;;
	    (netbsd)
		managers="pkgin"
		;;
	    (illumos)
		managers="pkg pkgin"
		;;
	    (solaris)
		managers="pkg"
		;;
	esac

	if [ -n "${managers-}" ]; then
	    break
	fi
    done

    if [ -n "${managers-}" ]; then
	printf "%s\n" $managers
    fi
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
