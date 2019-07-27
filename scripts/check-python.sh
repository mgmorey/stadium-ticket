#!/bin/sh

# check-python.sh: check that Python version meets requirement
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

check_python() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -x $1 ]
    python_output="$($1 --version || true)"

    if [ -z "$python_output" ]; then
	return 1
    fi

    version="${python_output#Python }"
    printf "Python %s interpreter found: %s\n" "$version" "$1"

    if ! $(find_system_python) "$script_dir/check-python.py" $version; then
	return 1
    fi

    return 0
)

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

if [ $# -eq 0 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ $# -gt 1 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"

check_python "$@"
