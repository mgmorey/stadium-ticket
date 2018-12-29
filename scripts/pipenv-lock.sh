#!/bin/sh -eu

# pipenv-lock: generate package requirement lists using pipenv
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

pipenv_lock() {
    $pipenv lock

    for file; do
	case $file in
	    (requirements-dev*.txt)
		opts=-d
		;;
	    (requirements.txt)
		opts=
		;;
	    (*)
		abort "%s: Invalid filename\n" "$file"
	esac

	printf "Generating %s\n" "$file"
	if $pipenv lock $opts -r >$tmpfile; then
	    /bin/mv -f $tmpfile "$file"
	    chgrp $(id -g) "$file"
	    chmod a+r "$file"
	else
	    abort "Unable to update %s\n" "$file"
	fi
    done
}

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "This script must be run as a non-privileged user"
fi

pipenv=$(which pipenv 2>/dev/null || true)
script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

cd "$source_dir"
tmpfile=$(mktemp)

trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

if [ -n "$pipenv" ]; then
    if [ $# -gt 0 ]; then
	pipenv_lock "$@"
    else
	pipenv_lock requirements*.txt
    fi
fi
