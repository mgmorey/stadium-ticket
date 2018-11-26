#!/bin/sh -u

# install-prerequisites: install prerequisite packages for building app
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

kernel_name=$(get-os-kernel-name)
script_dir=$(dirname $0)

case "$kernel_name" in
    (Linux|FreeBSD|SunOS)
	base_packages=$($script_dir/get-middleware-packages.sh)
	database_packages=$($script_dir/get-database-client-packages.sh)
	install-packages "$@" $base_packages $database_packages
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
