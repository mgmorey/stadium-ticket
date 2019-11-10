#!/bin/sh -eu

# get-devel-packages: get list of development packages
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

DARWIN_PKGS="bash curl gdbm libffi openssl readline sqlite xz zlib :git"

DEBIAN_10_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev \
make uuid-dev xz-utils zlib1g-dev"

FEDORA_PKGS="bash bzip2-devel curl gcc gdbm-devel libffi-devel \
libuuid-devel make ncurses-devel python3-devel openssl-devel \
readline-devel sqlite-devel xz-devel zlib-devel"

FREEBSD_11_PKGS="bash bzip2 curl gdbm gmake libffi lzma ncurses \
openssl-devel readline sqlite3"
FREEBSD_12_PKGS="bash bzip2 curl gdbm gmake libffi lzma ncurses \
openssl-devel readline sqlite3"

NETBSD_PKGS="bash bzip2 curl gdbm gmake libffi lzma ncurses readline \
sqlite3 :git"

OPENSUSE_PKGS="bash curl gcc gdbm-devel libbz2-devel libffi-devel \
libopenssl-devel lzma-sdk-devel make ncurses-devel python3-devel \
readline-devel sqlite3-devel uuid-devel zlib-devel"

REDHAT_7_PKGS="bash bzip2-devel curl gcc gdbm-devel libffi-devel \
libuuid-devel make ncurses-devel openssl-devel python3-devel \
readline-devel sqlite-devel xz-devel zlib-devel :git"
REDHAT_8_PKGS="bash bzip2-devel curl gcc gdbm-devel libffi-devel \
libuuid-devel make ncurses-devel openssl-devel python36-devel \
readline-devel sqlite-devel xz-devel zlib-devel"

SUNOS_PKGS="database/sqlite-3 developer/gcc developer/build/gnu-make \
library/libffi library/ncurses library/readline shell/bash"

UBUNTU_18_04_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev \
make uuid-dev xz-utils zlib1g-dev"
UBUNTU_19_04_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev \
make uuid-dev xz-utils zlib1g-dev"
UBUNTU_19_10_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev \
make uuid-dev xz-utils zlib1g-dev"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_devel_packages() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    case "$VERSION_ID" in
			(10)
			    packages=$DEBIAN_10_PKGS
			    ;;
		    esac
		    ;;
		(ubuntu|neon)
		    case "$VERSION_ID" in
			(18.04)
			    packages=$UBUNTU_18_04_PKGS
			    ;;
			(19.04)
			    packages=$UBUNTU_19_04_PKGS
			    ;;
			(19.10)
			    packages=$UBUNTU_19_10_PKGS
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
		(kali)
		    case "$VERSION_ID" in
			(2019.3)
			    packages=$DEBIAN_10_PKGS
			    ;;
		    esac
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
	    case "$VERSION_ID" in
		(11.*)
		    packages=$FREEBSD_11_PKGS
		    ;;
		(12.*)
		    packages=$FREEBSD_12_PKGS
		    ;;
	    esac
	    ;;
	(NetBSD)
	    packages=$NETBSD_PKGS
	    ;;
	(SunOS)
	    packages=$SUNOS_PKGS
	    ;;
    esac

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

eval $("$script_dir/get-os-release.sh" -X)

get_devel_packages
