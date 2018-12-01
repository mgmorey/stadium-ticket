#!/bin/sh -eu

# mysql.sh: wrapper for invoking MySQL client
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

script_dir=$(dirname $0)
source_dir=$script_dir/..

if . $source_dir/.env; then
    exec mysql \
	 -h ${DATABASE_HOST:-$MYSQL_HOST} \
	 -u ${DATABASE_USER:-$MYSQL_USER} \
	 -p"${DATABASE_PASSWORD:-$MYSQL_PASSWORD}" \
	 "$@"
fi
