#!/bin/sh -eu

# get-os-kernel-name: print short name of operating system kernel
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

system_name="$(uname -s)"

case "$system_name" in
    (Linux)
	printf "%s\n" "$system_name"
	;;
    (Darwin|FreeBSD|GNU|Minix|SunOS)
	printf "%s\n" "$system_name"
	;;
    (CYGWIN_NT-*)
	cygwin_name=${system_name%-*}
	kernel_name=${cygwin_name#*_}
	printf "%s\n" "$kernel_name"
	;;
    (*)
	abort "%s: Operating system not supported\n" "$system_name"
	;;
esac
