#!/bin/sh -eu

# install-uwsgi-from-source.sh: install uWSGI from source code
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
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ -x $1 ]; then
	return 0
    fi

    case $1 in
	(python3*)
	    $python uwsgiconfig.py --plugin plugins/python core ${1%_*}
	    ;;
	(uwsgi)
	    $python uwsgiconfig.py --build core
    esac
}

fetch_uwsgi_source() {
    if [ ! -d $HOME/git/uwsgi ]; then
	cd && mkdir -p git && cd git
	git clone https://github.com/unbit/uwsgi.git
    fi
}

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

install_uwsgi_binary() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case $1 in
	(*_plugin.so)
	    install_file 755 $1 $UWSGI_PLUGIN_DIR/$1
	    ;;
	(uwsgi)
	    install_file 755 $1 $UWSGI_BINARY_DIR/$1
	    ;;
    esac
}

install_uwsgi_from_source() (
    if [ $dryrun = false ]; then
	fetch_uwsgi_source
    fi

    if [ $dryrun = false ]; then
	cd $HOME/git/uwsgi
	python=$(find_system_python)

	for binary; do
	    build_uwsgi_binary $binary
	done
    fi

    for binary; do
	install_uwsgi_binary $binary
    done
)

if [ $# -gt 1 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

dryrun=${1-false}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
install_uwsgi_from_source $UWSGI_PLUGIN_NAME $UWSGI_BINARY_NAME
