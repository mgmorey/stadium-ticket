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

abort() {
    printf "$@" >&2
    exit 1
}

install() {
    for category in database-client http-client middleware; do
	printf "%s\n" "$script_dir/get-$category-packages.sh"
    done | sh | xargs install-packages "$@"
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu|centos|fedora|readhat|opensuse-*)
		install "$@"
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (FreeBSD|SunOS)
	install "$@"
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
