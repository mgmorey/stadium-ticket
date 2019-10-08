#!/bin/sh -eu

# install-epel: install Extra Packages for Enterprise Linux
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

EPEL_BASE_URL=https://dl.fedoraproject.org/pub/epel

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
	(Linux)
	    case "$ID" in
		(ol)
		    version=${VERSION_ID%.*}
		    ;;
		(centos)
		    version=$VERSION_ID
		    ;;
		esac
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

get_url() {
    printf "%s\n" "$EPEL_BASE_URL/epel-release-latest-$version.noarch.rpm"
}

install_epel() {
    validate_platform
    configure_platform

    if rpm -q epel-release >/dev/null 2>&1; then
	return 0
    fi

    manager=$("$script_dir/get-package-managers" | awk 'NR == 1 {print $0}')
    $manager install $(get_url)
}

validate_platform() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(ol|centos)
		    :
		    ;;
		(*)
		    abort_not_supported Distro
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

install_epel
