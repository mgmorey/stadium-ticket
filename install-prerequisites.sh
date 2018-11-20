#!/bin/sh -u

# install-prerequisites: install prerequisites
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

kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux|FreeBSD|SunOS)
	prerequisites=$(sh get-prerequisites.sh | sort)

	if [ -n "$prerequisites" ]; then
	    install-packages "$@" $prerequisites
	fi
	;;
esac

if [ -r requirements.txt ]; then
    python3 -m pip install --user -r requirements.txt
fi
