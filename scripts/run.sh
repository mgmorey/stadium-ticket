#!/bin/sh -eu

# run: wrapper for invoking "pipenv run" if pipenv present
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

if [ "$1" = -s -o "$1" = --sync ]; then
    sync=true
    shift
else
    sync=false
fi

if which pipenv >/dev/null 2>&1; then
    if [ "$sync" = true ]; then
	pipenv sync
    fi

    pipenv run "$@"
else
    "$@"
fi
