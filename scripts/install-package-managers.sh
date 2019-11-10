#!/bin/sh -eu

# install-package-managers: install non-native package managers
# Copyright (C) 2019  "Michael G. Morey" <mgmorey@gmail.com>

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

INSTALL_BREW=install-homebrew
INSTALL_PKGIN=install-pkgsrc
INSTALL_PKGUTIL=install-opencsw

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
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

install_package_manager() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "$(basename $1)" in
	(brew)
	    "$script_dir/$INSTALL_BREW.sh"
	    ;;
	(pkgin)
	    "$script_dir/$INSTALL_PKGIN.sh"
	    ;;
	(pkgutil)
	    "$script_dir/$INSTALL_PKGUTIL.sh"
	    ;;
    esac
}

install_package_managers() {
    for manager; do
	if ! which $manager >/dev/null 2>&1; then
	    install_package_manager $manager
	fi
    done
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -x)

install_package_managers "$@"