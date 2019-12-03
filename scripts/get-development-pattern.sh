#!/bin/sh -eu

# get-development-pattern: get essential build/development pattern
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

DEBIAN_PATTERN="build-essential"

OPENSUSE_PATTERN="devel_basis"

REDHAT_PATTERN="Development Tools"

ILLUMOS_PATTERN="build-essential"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_devel_pattern() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (debian)
		pattern=$DEBIAN_PATTERN
		;;
	    (opensuse)
		pattern=$OPENSUSE_PATTERN
		;;
	    (rhel|fedora)
		pattern=$REDHAT_PATTERN
		;;
	    (illumos)
		pattern=$ILLUMOS_PATTERN
		;;
	esac

	if [ -n "${pattern-}" ]; then
	    break
	fi
    done

    if [ -n "${pattern-}" ]; then
	printf "%s\n" "$pattern"
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

eval $("$script_dir/get-os-release.sh" -x)

get_devel_pattern