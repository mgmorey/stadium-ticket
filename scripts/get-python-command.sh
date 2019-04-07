#!/bin/sh -eu

# get-python-command: get Python 3 command binary or module
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

PYTHON=python3

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

module="$1"
interpreter="${2:-$PYTHON}"

case "$interpreter" in
    (python|python[23])
	;;
    (*)
	abort "%s: Invalid interpreter\n" "$interpreter"
esac

case "$module" in
    (pip|pip3|pipenv|virtualenv)
	;;
    (*)
	abort "%s: Invalid command\n" "$module"
esac

for command in $module "$interpreter -m $module" false; do
    if $command --version >/dev/null 2>&1; then
	break
    fi
done

printf "%s\n" "$command"
