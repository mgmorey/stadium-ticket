#!/bin/sh -eu

# build-uwsgi.sh: download and build uWSGI from GitHub source
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

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

build_uwsgi_binary() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ -x $2 ]; then
	return 0
    fi

    case $2 in
	(uwsgi)
	    $1 uwsgiconfig.py --build core
	    ;;
	(*)
	    $1 uwsgiconfig.py --plugin plugins/python core ${2%_*}
	    ;;
    esac
}

build_uwsgi_from_source() (
    assert [ $# -ge 3 -a $# -le 4 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    python=$1
    python_version=$2
    shift 2
    fetch_uwsgi_source

    if ! cd "$HOME/git/$UWSGI_BRANCH"; then
	return 1
    fi

    for binary; do
	build_uwsgi_binary $python $binary
    done
)

fetch_uwsgi_source() {
    if [ -d "$HOME/git/$UWSGI_BRANCH" ]; then
	return 0
    fi

    cd
    mkdir -p git
    cd git
    git clone -b $UWSGI_BRANCH $UWSGI_URL $UWSGI_BRANCH
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

if [ $# -lt 2 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ $# -gt 2 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

if [ $# -eq 2 ]; then
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    SYSTEM_PYTHON=$1
    SYSTEM_PYTHON_VERSION=$2
    shift 2
fi

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$script_dir/..

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_system
set_unpriv_environment
build_uwsgi_from_source $SYSTEM_PYTHON $SYSTEM_PYTHON_VERSION \
			$UWSGI_BINARY_NAME $UWSGI_PLUGIN_NAME
