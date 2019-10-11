#!/bin/sh -eu

# install-extra-packages: install extra packages
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

install_extras() {
    invoke_usermod=true

    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    case "$VERSION_ID" in
			# (9)
			#     :
			#     ;;
			(10)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ubuntu|neon)
		    case "$VERSION_ID" in
			(18.04)
			    :
			    ;;
			(19.04)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(linuxmint)
		    case "$VERSION_ID" in
			(19.2)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(kali)
		    case "$VERSION_ID" in
			(2019.3)
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
			(30)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(ol)
		    case "$VERSION_ID" in
			(7.7)
			    :
			    ;;
			(8.0)
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
			(8)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    case "$VERSION_ID" in
		(10.14.*)
		    :
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(FreeBSD)
	    invoke_usermod=false

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
	(NetBSD)
	    invoke_usermod=false
	    ;;
	(SunOS)
	    invoke_usermod=false
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    packages=$("$script_dir/get-extra-packages.sh")
    "$script_dir/install-packages.sh" $packages
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_extras
