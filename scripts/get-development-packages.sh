#!/bin/sh -eu

# get-development-packages: get list of development packages
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

CENTOS_7_PKGS="autoconf automake gcc libtool make pkgconfig"

DEBIAN_PKGS="autoconf automake gcc libtool make pkgconf"

FEDORA_PKGS="autoconf automake gcc libtool make pkgconf"

ILLUMOS_PKGS="developer/build/autoconf developer/build/automake \
developer/build/gnu-make developer/build/libtool developer/build/pkg-config \
developer/illumos-gcc system/header"

OPENSUSE_PKGS="autoconf automake gcc libtool make pkgconf"

REDHAT_7_PKGS="autoconf automake gcc libtool make pkgconfig"

REDHAT_8_PKGS="autoconf automake gcc libtool make pkgconf"

SOLARIS_PKGS="developer/build/autoconf developer/build/automake \
developer/build/gnu-make developer/build/libtool developer/build/pkg-config \
developer/developerstudio-126/cc developer/developerstudio-126/library/c-libs \
system/header"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_emacs_build_deps() {
    packages=

    for id in $ID $ID_LIKE; do
	case "$id" in
	    (centos)
		case "$VERSION_ID" in
		    (7)
			packages=$CENTOS_7_PKGS
			;;
		esac
		;;
	    (debian)
		packages=$DEBIAN_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (opensuse)
		packages=$OPENSUSE_PKGS
		;;
	    (rhel|ol)
		case "$VERSION_ID" in
		    (7.*)
			packages=$REDHAT_7_PKGS
			;;
		    (8.*)
			packages=$REDHAT_8_PKGS
			;;
		esac
		;;
	    (illumos)
		packages=$ILLUMOS_PKGS
		;;
	    (solaris)
		packages=$SOLARIS_PKGS
		;;
	esac

	if [ -n "${packages-}" ]; then
	    break
	fi
    done

    if [ -n "${packages-}" ]; then
	printf "%s\n" $packages
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

get_emacs_build_deps