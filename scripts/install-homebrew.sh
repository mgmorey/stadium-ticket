#!/bin/sh -u

# install-homebrew: install HomeBrew (for Darwin platform)
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

HOMEBREW_URL=https://raw.githubusercontent.com/Homebrew/install/master/install

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

eval $(sh -eu $script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Darwin)
	if ! brew info >/dev/null 2>&1; then
	    /usr/bin/ruby -e $expr "$(curl -fsSL $HOMEBREW_URL)"
	fi
    	;;
    (*)
	abort "%s: Operating system not supported\n" "$pretty_name"
	;;
esac
