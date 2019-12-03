#!/bin/sh -eu

# get-python-build-packages: get list of Python build packages
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

# Wiki page: https://github.com/pyenv/pyenv/wiki

CENTOS_7_PKGS="bzip2-devel gdbm-devel libffi-devel libuuid-devel ncurses-devel \
openssl-devel python3-devel readline-devel sqlite-devel xz-devel zlib-devel"

DARWIN_PKGS="gdbm libffi openssl readline sqlite xz zlib"

DEBIAN_10_PKGS="libbz2-dev libffi-dev libgdbm-dev libncurses5-dev \
libncursesw5-dev libpython3-dev libreadline-dev libsqlite3-dev \
libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev uuid-dev \
xz-utils zlib1g-dev"

FEDORA_PKGS="bzip2-devel gdbm-devel libffi-devel libuuid-devel ncurses-devel \
openssl-devel python3-devel readline-devel sqlite-devel xz-devel zlib-devel"

FREEBSD_11_PKGS="bzip2 gdbm libffi lzma ncurses readline sqlite3"
FREEBSD_12_PKGS="bzip2 gdbm libffi lzma ncurses openssl111 readline sqlite3"

ILLUMOS_PKGS="database/sqlite-3 library/libffi library/ncurses library/readline"

NETBSD_PKGS="bzip2 gdbm libffi lzma ncurses readline sqlite3"

OPENSUSE_PKGS="gdbm-devel libbz2-devel libffi-devel libopenssl-devel \
lzma-sdk-devel ncurses-devel python3-devel readline-devel sqlite3-devel \
uuid-devel zlib-devel"

REDHAT_7_PKGS="bzip2-devel gdbm-devel libffi-devel libuuid-devel ncurses-devel \
openssl-devel python3-devel readline-devel sqlite-devel xz-devel zlib-devel"
REDHAT_8_PKGS="bzip2-devel gdbm-devel libffi-devel libuuid-devel ncurses-devel \
openssl-devel python36-devel readline-devel sqlite-devel xz-devel zlib-devel"

SOLARIS_PKGS="database/sqlite-3 library/libffi library/ncurses library/pcre \
library/readline system/header"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_python_build_deps() {
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
		case "$VERSION_ID" in
		    (10)
			packages=$DEBIAN_10_PKGS
			;;
		esac
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (kali)
		case "$VERSION_ID" in
		    (2019.3)
			packages=$DEBIAN_10_PKGS
			;;
		esac
		;;
	    (linuxmint)
		case "$VERSION_ID" in
		    (19.2)
			packages=$DEBIAN_10_PKGS
			;;
		esac
		;;
	    (opensuse-*)
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
	    (ubuntu|neon)
		case "$VERSION_ID" in
		    (18.04)
			packages=$DEBIAN_10_PKGS
			;;
		    (19.04)
			packages=$DEBIAN_10_PKGS
			;;
		    (19.10)
			packages=$DEBIAN_10_PKGS
			;;
		esac
		;;
	    (darwin)
		packages=$DARWIN_PKGS
		;;
	    (freebsd)
		case "$VERSION_ID" in
		    (11.*)
			packages=$FREEBSD_11_PKGS
			;;
		    (12.*)
			packages=$FREEBSD_12_PKGS
			;;
		esac
		;;
	    (illumos)
		packages=$ILLUMOS_PKGS
		;;
	    (netbsd)
		packages=$NETBSD_PKGS
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

get_python_build_deps