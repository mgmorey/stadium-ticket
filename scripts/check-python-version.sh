#!/bin/sh -eu

# check-environment: check environment for required toolchain
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

PYTHONS="python3 python false"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

check_python_version() {
    python_output=$($1 --version)
    python_version="${python_output#Python }"
    printf "Python interpreter %s " "$python"
    printf "is version %s\n" "$python_version"

    if ! $script_dir/check-python-version.py "$python_version"; then
	abort_no_python
    fi
}

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

script_dir=$(get_path "$(dirname "$0")")

for python in $PYTHONS; do
    if $python --version >/dev/null 2>&1; then
	break
    fi
done

if [ "$python" != false ]; then
    if pyenv --version >/dev/null 2>&1; then
	which="pyenv which"
    else
	which=which
    fi

    python=$($which $python)

    if [ -z "$python" ]; then
	abort_no_python
    fi

    check_python_version $python
else
    abort_no_python
fi
