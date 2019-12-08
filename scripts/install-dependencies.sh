#!/bin/sh -eu

# install-dependencies: install prerequisites for developing app
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

install_dependencies() {
    validate_platform
    packages=$("$script_dir/get-dependencies.sh")
    pattern=$("$script_dir/get-development-pattern.sh")

    if [ -n "$packages" ]; then
	install-packages ${pattern:+-p "$pattern" }$packages
    fi

    if [ -n "${package:-}" ]; then
	install-build-deps "$@" $package
    fi
}

validate_platform() {
    case "$ID" in
	(debian|raspbian)
	    case "$VERSION_ID" in
		(10)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(ubuntu)
	    case "$VERSION_ID" in
		(18.04)
		    :
		    ;;
		(19.10)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(opensuse-leap)
	    case "$VERSION_ID" in
		(15.0|15.1)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(opensuse-tumbleweed)
	    case "$VERSION_ID" in
		(2019*)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(fedora)
	    case "$VERSION_ID" in
		(31)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(rhel|ol)
	    case "$VERSION_ID" in
		(7.[78])
		    :
		    ;;
		(8.[012])
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(centos)
	    case "$VERSION_ID" in
		(7)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(freebsd)
	    case "$VERSION_ID" in
		(11.*)
		    :
		    ;;
		(12.*)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(illumos)
	    case "$VERSION_ID" in
		(2019.10)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(macos)
	    case "$VERSION_ID" in
		(10.14.*)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(netbsd)
	    :
	    ;;
	(solaris)
	    case "$VERSION_ID" in
		(11.4)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -x)

install_dependencies
