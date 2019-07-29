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

install_docker_group() {
    if ! getent group docker >/dev/null; then
	groupadd docker
    fi

    if [ "$invoke_usermod" = true ]; then
	docker_users="$(getent group docker | awk -F: '{print $4}')"

	if ! printf "%s\n" "$docker_users" | grep -q "$SUDO_USER"; then
	    usermod -a -G docker $SUDO_USER
	    printf "Please log out and back in again to enable the new group\n"
	fi
    fi
}

install_extras() {
    invoke_usermod=true

    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    case "$VERSION_ID" in
			(9|10)
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
			(19.04)
			    :
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(opensuse-*)
		    :
		    ;;
		(fedora)
		    :
		    ;;
		(redhat|ol)
		    :
		    ;;
		(centos)
		    "$script_dir/install-packages.sh" epel-release
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    :
	    ;;
	(FreeBSD)
	    invoke_usermod=false
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

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	install_docker_group
    fi
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_extras
