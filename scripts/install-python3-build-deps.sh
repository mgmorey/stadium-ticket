#!/bin/sh -eu

# install-python3-build-deps: install Python 3 build dependencies
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

DARWIN_PKG_DIR=/Library/Developer/CommandLineTools/Packages/
DARWIN_PKG_NAME=macOS_SDK_headers_for_macOS_10.14.pkg

DEBIAN_PKG=python3-defaults

abort() {
    printf "$@" >&2
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
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
    (Linux)
	case "$ID" in
	    (debian|raspbian|ubuntu)
		package=$DEBIAN_PKG
	    	;;
	    (opensuse-*)
		:
	    	;;
	    (fedora|redhat|centos)
		:
		;;
	    (*)
		abort_not_supported Distro
		;;
	esac
	;;
    (Darwin)
	sudo installer -pkg $DARWIN_PKG_DIR/$DARWIN_PKG_NAME -target /
    	;;
    (FreeBSD|SunOS|NT)
	:
    	;;
    (*)
	abort_not_supported "Operating system"
	;;
esac

install_cmd=$("$script_dir/get-pattern-install-command.sh")
install_opts=$("$script_dir/get-package-install-options.sh")
installer=$("$script_dir/get-package-manager.sh")
packages=$("$script_dir/get-python3-build-deps.sh")
pattern=$("$script_dir/get-devel-pattern.sh")

if [ -n "$pattern" ]; then
     $installer $install_cmd $install_opts "$pattern"
fi

if [ -n "${package:-}" ]; then
    "$script_dir/install-build-deps.sh" "$@" $package || true
fi

if [ -n "$packages" ]; then
    $installer install $install_opts $packages
fi
