#!/bin/sh -eu

# get-python-devel-packages: get list of Python development packages
# Copyright (C) 2019  "Michael G. Morey" <mgmorey@gmail.com>

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

DARWIN_PKGS=":%s-codestyle :%s-packaging :%s-pylint :%s-test"

DEBIAN_10_PKGS="pylint3 %s-packaging %s-pip %s-pycodestyle %s-pytest \
%s-venv %s-virtualenv"

FREEBSD_PKGS="pylint-%s %s-packaging %s-pip %s-pycodestyle %s-pytest \
%s-virtualenv"

FEDORA_PKGS="%s-packaging %s-pip %s-pycodestyle %s-pylint %s-pytest \
%s-virtualenv"

NETBSD_PKGS="%s-codestyle %s-packaging %s-pip %s-pylint %s-test \
%s-virtualenv"

OPENSUSE_PKGS="%s-packaging %s-pip %s-pycodestyle %s-pylint %s-pytest \
%s-virtualenv"

REDHAT_PKGS="%s-pip %s-pycodestyle %s-pytest %s-virtualenv"

SUNOS_PKGS=":%s-codestyle :%s-packaging :%s-pylint :%s-test"

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

get_python_devel_packages() {
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
			    packages=$DEBIAN_10_PKGS
			    ;;
			(19.04)
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
		(fedora)
		    packages=$FEDORA_PKGS
		    ;;
		(ol)
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

    data=$("$script_dir/get-python-metadata.sh")
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
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_python_devel_packages
