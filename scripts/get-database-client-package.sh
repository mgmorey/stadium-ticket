#!/bin/sh -eu

# get-database-client-package: get database client package name
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

AWKEXPR='{
n = split($0, a, "-");

for(i = 1; i < n; i++) {
    if (i > 1) {
        printf("-%s", a[i])}
    else {
        printf("%s", a[i])
    }
}

printf("\n")
}'
REGEX='^(mariadb|mysql)[0-9]+-client ^(mariadb|mysql)[0-9]+'

script_dir=$(dirname $0)
tmpfile=$(mktemp)

trap "/bin/rm -f $tmpfile" 0 INT QUIT TERM

command="$script_dir/get-package-list-command.sh"

if [ -n "$command" ]; then
    "$command" | sh | awk '{print $1}' | awk "$AWKEXPR" >$tmpfile

    for regex in $REGEX; do
	if egrep $regex $tmpfile; then
	    break
	fi
    done
fi
