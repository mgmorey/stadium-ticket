# -*- Mode: Shell-script -*-

# common-functions.sh: define commonly used shell functions
# Copyright (C) 2019  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_bin_directory() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    dir=$1

    while [ "$(dirname "$dir")" != / ]; do
	dir="$(dirname "$dir")"

	if [ -d "$dir/bin" ]; then
	    printf "$dir/bin"
	    return
	fi
    done
)
