#!/bin/sh -eu

# get-devel-packages: get list of Python development packages
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

DARWIN_PKGS="bash curl gdbm libffi openssl readline sqlite xz zlib"

DEBIAN_9_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl1.0-dev libxml2-dev liblzma-dev make rsync \
uuid-dev xz-utils zlib1g-dev"

DEBIAN_10_PKGS="bash curl gcc libbz2-dev libffi-dev libgdbm-dev \
libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev liblzma-dev \
make rsync uuid-dev xz-utils zlib1g-dev"

FREEBSD_PKGS="bash bzip2 curl gdbm gmake libffi llvm50 lzma ncurses \
readline rsync sqlite3"

NETBSD_PKGS="bash bzip2 curl gdbm gmake libffi lzma ncurses readline sqlite3"

OPENSUSE_PKGS="bash curl gcc gdbm-devel libbz2-devel libffi-devel \
libopenssl-devel lzma-sdk-devel make ncurses-devel openssl-devel \
python3-devel readline-devel rsync sqlite3-devel uuid-devel zlib-devel"

REDHAT_PKGS="bash bzip2-devel curl gcc gdbm-devel libffi-devel libuuid-devel \
make ncurses-devel python3-devel openssl-devel readline-devel rsync
sqlite-devel xz-devel zlib-devel"

SUNOS_PKGS="bash database/sqlite-3 gcc-6 libffi make ncurses readline rsync"

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

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

case "$kernel_name" in
    (Linux|GNU)
	case "$ID" in
	    (debian|raspbian)
		case "$VERSION_ID" in
		    (9)
			packages=$DEBIAN_9_PKGS
			;;
		    (10)
			packages=$DEBIAN_10_PKGS
			;;
		esac
		;;
	    (ubuntu)
		packages=$DEBIAN_10_PKGS
		;;
	    (opensuse-*)
		packages=$OPENSUSE_PKGS
		;;
	    (fedora|redhat|centos|ol)
		packages=$REDHAT_PKGS
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

data=$("$script_dir/get-python-package.sh")
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

for package in ${packages-}; do
    case $package in
	(*%s*)
	    printf "$package\n" $package_modifier
	    ;;
	(*)
	    printf "%s\n" $package
	    ;;
    esac
done
