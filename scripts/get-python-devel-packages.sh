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

DARWIN_PKGS=":%s-codestyle :%s-packaging :%s-pip :%s-pylint :%s-test \
:%s-virtualenv"

DEBIAN_PKGS="pylint3 %s-openssl %s-packaging %s-pip %s-pycodestyle \
%s-pytest %s-venv %s-virtualenv virtualenv"

FREEBSD_PKGS="pylint-%s %s-packaging %s-pip %s-pycodestyle %s-pytest \
%s-virtualenv"

FEDORA_PKGS="%s-packaging %s-pip %s-pycodestyle %s-pylint %s-pytest \
%s-virtualenv"

ILLUMOS_PKGS=":%s-codestyle :%s-packaging :%s-pip :%s-pylint :%s-test \
:%s-virtualenv"

NETBSD_PKGS="%s-codestyle %s-packaging %s-pip %s-pylint %s-test \
%s-virtualenv"

OPENSUSE_PKGS="%s-packaging %s-pip %s-pycodestyle %s-pylint %s-pytest \
%s-virtualenv"

REDHAT_7_PKGS=":%s-codestyle :%s-packaging :%s-pip :%s-pylint :%s-test \
:%s-virtualenv"
REDHAT_8_PKGS="%s-pip %s-pytest %s-virtualenv"

SOLARIS_PKGS="developer/python/pylint-%s library/python/pip-%s \
library/python/pytest-%s library/python/virtualenv-%s"

UBUNTU_18_PKGS="pylint3 %s-openssl %s-packaging %s-pip %s-pycodestyle \
%s-pytest %s-venv %s-virtualenv virtualenv"
UBUNTU_19_PKGS="pylint %s-openssl %s-packaging %s-pip %s-pycodestyle \
%s-pytest %s-venv %s-virtualenv virtualenv"

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
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (debian)
		packages=$DEBIAN_PKGS
		;;
	    (ubuntu)
		case "$VERSION_ID" in
		    (18.*)
			packages=$UBUNTU_18_PKGS
			;;
		    (19.*)
			packages=$UBUNTU_19_PKGS
			;;
		esac
		;;
	    (opensuse)
		packages=$OPENSUSE_PKGS
		;;
	    (fedora)
		packages=$FEDORA_PKGS
		;;
	    (rhel|ol|centos)
		case "$VERSION_ID" in
		    (7|7.*)
			packages=$REDHAT_7_PKGS
			;;
		    (8|8.*)
			packages=$REDHAT_8_PKGS
			;;
		esac
		;;
	    (darwin)
		packages=$DARWIN_PKGS
		;;
	    (freebsd)
		packages=$FREEBSD_PKGS
		;;
	    (netbsd)
		packages=$NETBSD_PKGS
		;;
	    (illumos)
		packages=$ILLUMOS_PKGS
		;;
	    (solaris)
		packages=$SOLARIS_PKGS
		;;
	esac

	if [ -n "${packages-}" ]; then
	    break
	fi
    done

    "$script_dir/get-python-packages.sh" ${packages-}
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_python_devel_packages
