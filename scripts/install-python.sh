#!/bin/sh -eu

# install-python: build and install Python interpreter via pyenv
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

AWK_EXPR='/^  [0-9]+([.][0-9]+){0,2}$/ {print $1}'

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
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

get_all_python_versions() {
    pyenv install --list | awk "$AWK_EXPR" | sort -Vr
}

get_python_version() {
    python=$(find_bootstrap_python)
    python_versions=$($python "$script_dir/check-python.py")

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	versions="$(get_all_python_versions)"

	for version in $versions; do
	    case $version in
		($python_version.*)
		    printf "%s\n" $version
		    return
	    esac
	done
    done
}

install_python() {
    pyenv install -s ${1-$(get_python_version)}
}

script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"

if ! pyenv --version >/dev/null 2>&1; then
    abort "%s: No pyenv found in PATH\n" "$0"
fi

install_python "$@"
