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

    if [ -x $1 ]; then
	return
    fi

    find_system_python

    case $1 in
	(python3*)
	    $python uwsgiconfig.py --plugin plugins/python core ${1%_*}
	    ;;
	(uwsgi)
	    $python uwsgiconfig.py --build core
    esac
}

fetch_uwsgi_source() {
    if [ $dryrun = false ]; then
	if [ ! -d $HOME/git/uwsgi ]; then
	    cd && mkdir -p git && cd git
	    git clone https://github.com/unbit/uwsgi.git
	fi
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

install_uwsgi_binaries() {
    (
	cd $HOME/git/uwsgi

	if [ $dryrun = false ]; then
	    for binary; do
		build_uwsgi_binary $binary
	    done
	fi

	for binary; do
	    install_uwsgi_binary $binary
	done
    )
}

install_uwsgi_binary() {
    case $binary in
	(*_plugin.so)
	    install_file 755 $1 $UWSGI_PLUGIN_DIR/$1
	    ;;
	(uwsgi)
	    install_file 755 $1 $UWSGI_BINARY_DIR/$1
	    create_symlink $UWSGI_BINARY_DIR/$1 /usr/local/bin/$1
	    ;;
    esac
}

dryrun=${1-false}
script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
fetch_uwsgi_source
install_uwsgi_binaries $UWSGI_PLUGIN_NAME $UWSGI_BINARY_NAME
