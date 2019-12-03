#!/bin/sh -eu

# get-python-devel-packages: get list of Python PIP packages
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

DARWIN_PKGS=":%s-packaging :%s-pip"

DEBIAN_PKGS="%s-packaging %s-pip"

FREEBSD_PKGS="%s-packaging %s-pip"

FEDORA_PKGS="%s-packaging %s-pip"

ILLUMOS_PKGS=":%s-packaging :%s-pip"

NETBSD_PKGS="%s-packaging %s-pip"

OPENSUSE_PKGS="%s-packaging %s-pip"

REDHAT_7_PKGS=":%s-packaging :%s-pip"
REDHAT_8_PKGS="%s-pip"

SOLARIS_PKGS="library/python/pip-%s"

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
		packages="$DEBIAN_PKGS pylint3"
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
	    (ubuntu)
		case "$VERSION_ID" in
		    (18.*)
			packages="$DEBIAN_PKGS pylint3"
			;;
		    (19.*)
			packages="$DEBIAN_PKGS pylint"
			;;
		esac
		;;
	    (darwin)
		packages=$DARWIN_PKGS
		;;
	    (freebsd)
		packages=$FREEBSD_PKGS
		;;
	    (illumos)
		packages=$ILLUMOS_PKGS
		;;
	    (netbsd)
		packages=$NETBSD_PKGS
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

eval $("$script_dir/get-os-release.sh" -x)

get_python_devel_packages