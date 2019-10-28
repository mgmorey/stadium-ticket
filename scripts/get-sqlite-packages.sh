#!/bin/sh -eu

# get-sqlite-packages: get SQLite3 package names
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

DARWIN_PKGS=":%s-sqlite3 sqlite"

DEBIAN_PKGS="sqlite3"

FEDORA_PKGS="sqlite"

FREEBSD_PKGS="%s-sqlite3 sqlite3"

NETBSD_PKGS="%s-sqlite3 sqlite3"

OPENSUSE_PKGS="sqlite3"

REDHAT_7_PKGS=":%s-sqlite3 sqlite"
REDHAT_8_PKGS="sqlite"

SUNOS_PKGS="database/sqlite-3 :%s-sqlite3"

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

get_sqlite_packages() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu|linuxmint|neon|kali)
		    packages=$DEBIAN_PKGS
		    ;;
		(opensuse-*)
		    packages=$OPENSUSE_PKGS
		    ;;
		(fedora)
		    packages=$FEDORA_PKGS
		    ;;
		(rhel|ol|centos)
		    case "$VERSION_ID" in
			(7|7.[78])
			    packages=$REDHAT_7_PKGS
			    ;;
			(8|8.[01])
			    packages=$REDHAT_8_PKGS
			    ;;
		    esac
		    ;;
	    esac
	    ;;
	(Darwin)
	    packages=$DARWIN_PKGS
	    ;;
	(FreeBSD)
	    packages=$FREEBSD_PKGS
	    ;;
	(NetBSD)
	    packages=$NETBSD_PKGS
	    ;;
	(SunOS)
	    packages=$SUNOS_PKGS
	    ;;
    esac

    "$script_dir/get-python-packages.sh" ${packages-}
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_sqlite_packages
