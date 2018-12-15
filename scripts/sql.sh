#!/bin/sh -eu

# sql.sh: wrapper for invoking SQL database client
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

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

script=

while getopts 'x:' OPTION; do
    case $OPTION in
	('x')
	    script="$OPTARG"
	    ;;
	('?')
	    printf "Usage: %s: [-x <SCRIPT>]\n" $(basename $0) >&2
	    exit 2
	    ;;
    esac
done
shift $(($OPTIND - 1))

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..
sql_dir=$source_dir/sql

if . $source_dir/.env; then
    if [ -n "$script" ]; then
	exec <"$sql_dir/$script-$DATABASE_DIALECT.sql"
    fi

    case $DATABASE_DIALECT in
	(mysql)
	    exec $DATABASE_DIALECT \
		 -h ${DATABASE_HOST:-$localhost} \
		 -u ${DATABASE_USER:-$USER} \
		 -p"${DATABASE_PASSWORD:-}"
	    ;;
	(sqlite)
	    exec sqlite3 /tmp/${DATABASE_SCHEMA:-default}.db
	    ;;
    esac
fi
