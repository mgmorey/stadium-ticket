#!/bin/sh -eu

# install-docker: install Docker packages
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

DOCKER_GROUP_ID=docker

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

configure_platform() {
    case "$kernel_name" in
	(FreeBSD)
	    invoke_usermod=false
	    ;;
	(*)
	    invoke_usermod=true
	    ;;
    esac
}

get_architecture() {
    machine=$(uname -m)

    case "$machine" in
	(x86_64)
	    printf "%s\n" amd64
	    ;;
	(armv7l)
	    printf "%s\n" armhf
	    ;;
	(*)
	    printf "%s\n" $machine
	    ;;
    esac
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

install_docker() {
    validate_platform
    configure_platform
    installed_package=$("$script_dir/get-installed-docker-package.sh")

    case $installed_package in
	(docker|docker.io)
	    printf "Package $installed_package is installed\n"
	    exit 0
	    ;;
	(docker-ce)
	    printf "Removing $installed_package\n"

	    if ! apt-get remove $installed_package; then
		exit $?
	    fi
	    ;;
	(*)
	    printf "No Docker package installed\n"
    esac

    packages=$("$script_dir/get-docker-packages.sh")

    if [ -n "$packages" ]; then
	printf "Installing Docker\n"

	if "$script_dir/install-packages.sh" $packages; then
	    postinstall_docker
	else
	    exit $?
	fi
    fi
}

install_docker_group() {
    if [ "$invoke_usermod" = false ]; then
	return 0
    fi

    if ! getent group $DOCKER_GROUP_ID >/dev/null; then
	groupadd $DOCKER_GROUP_ID
    fi

    members="$(getent group $DOCKER_GROUP_ID | awk -F: '{print $4}')"

    if ! printf "%s\n" "$members" | grep -q "\<$SUDO_USER\>"; then
	usermod -a -G $DOCKER_GROUP_ID $SUDO_USER
	printf "Please restart the machine before using docker\n"
    fi
}

postinstall_docker() {
    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	install_docker_group
    fi
}

validate_platform() {
    arch=$(get_architecture)

    case "$arch" in
	(amd64)
	    :
	    ;;
	(*)
	    abort "%s: %s: Architecture not supported" "$0" "$arch"
	    ;;
    esac

    case "$kernel_name" in
	(Linux|GNU)
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
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_docker
