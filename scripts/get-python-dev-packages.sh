#!/bin/sh -eu

# get-python-dev-packages: get Python development package names
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

DEBIAN_PKGS="build-essential gcc libbz2-dev libffi-dev libgdbm-dev liblzma-dev \
libncurses5-dev libreadline-dev libsodium-dev libsqlite3-dev libssl-dev make \
pycodestyle pylint3 %s-bcrypt %s-dev %s-nacl %s-pip %s-pycodestyle %s-pytest \
%s-virtualenv virtualenv zlib1g-dev"

FEDORA_PKGS="bzip2-devel gcc libffi-devel libsodium-devel lzma-devel make \
ncurses-devel openssl-devel %s-devel %s-pip %s-pycodestyle %s-pytest \
%s-virtualenv readline-devel sqlite-devel"

FREEBSD_PKGS="bash gmake libffi libsodium ncurses pylint-%s %s-bz2file %s-lzma \
%s-pip %s-pycodestyle %s-pytest %s-sqlite3 %s-virtualenv"

OPENSUSE_PKGS="gcc gdbm-devel libbz2-devel libffi-devel libopenssl-devel \
libsodium-devel lzma-sdk-devel make ncurses-devel %s-devel %s-pip \
%s-pycodestyle %s-pylint %s-pylzma %s-pytest %s-virtualenv \
readline-devel sqlite3-devel"

REDHAT_PKGS="bzip2-devel gcc libffi-devel libsodium-devel make ncurses-devel \
openssl-devel pylint %s-devel %s-pip %s-pytest %s-virtualenv pytest \
readline-devel sqlite-devel"

SUNOS_PKGS="build-essential pip-%s"

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
distro_name=$(sh -eu $script_dir/get-os-distro-name.sh)
kernel_name=$(sh -eu $script_dir/get-os-kernel-name.sh)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu)
		packages=$DEBIAN_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (redhat|centos)
		packages=$REDHAT_PKGS
		;;
	    (opensuse-*)
		packages=$OPENSUSE_PKGS
		;;
	esac
	;;
    (FreeBSD)
	packages=$FREEBSD_PKGS
	;;
    (SunOS)
	packages=$SUNOS_PKGS
	;;
esac

data=$(sh -eu $script_dir/get-python-package.sh)
package_name=$(printf "%s" "$data" | awk '{print $1}')
package_modifier=$(printf "%s" "$data" | awk '{print $2}')

printf "%s\n" $package_name

for package in ${packages:-}; do
    case $package in
	(*%s*)
	    printf "$package\n" $package_modifier
	    ;;
	(*)
	    printf "%s\n" $package
	    ;;
    esac
done
