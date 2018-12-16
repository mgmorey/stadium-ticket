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

abort() {
    printf "$@" >&2
    exit 1
}

exec_sql() {
    case "$DATABASE_DIALECT" in
	(mysql)
	    exec "$DATABASE_DIALECT" \
		 -h"${DATABASE_HOST:-$localhost}" \
		 -u"${DATABASE_USER:-$USER}" \
		 -p"${DATABASE_PASSWORD:-}"
	    ;;
	(sqlite)
	    exec sqlite3 "/tmp/${DATABASE_SCHEMA:-default}.db"
	    ;;
    esac
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

script=
script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..
sql_dir=$source_dir/sql

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

if . "$source_dir/.env"; then
    if [ -n "$script" ]; then
	exec <"$sql_dir/$script-$DATABASE_DIALECT.sql"
    fi

    exec_sql
else
    abort "%s: No such environment file\n" "$source_dir/.env"
fi
