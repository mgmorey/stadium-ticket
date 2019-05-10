#!/bin/sh -eu

# install-uwsgi.sh: install uWSGI
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

start_uwsgi() {
    systemctl enable uwsgi
    systemctl start uwsgi
}

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

dryrun=${1-false}
script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"

eval $("$script_dir/get-os-release.sh" -X)

case "$kernel_name" in
    (Darwin)
	"$script_dir/install-uwsgi-from-source.sh" $dryrun
	;;
    (*)
	if [ $dryrun = true ]; then
	    :
	else
	    is_installed=true

	    for package in $("$script_dir/get-uwsgi-packages.sh"); do
		if ! "$script_dir/is-installed.sh" $package; then
		    is_installed=false
		    break
		fi
	    done

	    if [ $is_installed = false ]; then
		"$script_dir/install-packages.sh" $packages
	    fi

	    start_uwsgi
	fi
	;;
esac
