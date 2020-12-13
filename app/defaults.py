# -*- coding: utf-8 -*-
# Copyright (C) 2020  "Michael G. Morey" <mgmorey@gmail.com>

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

"""Represent a dicionary of defaults keyed by parameter and SQL
dialect."""

from .hostname import get_hostname

DEFAULT = {
    'charset': {
        'mysql': 'utf8mb4',
    },
    'dialect': {
        None: 'sqlite',
    },
    'driver': {
        'mysql': 'pymysql',
        'postgresql': 'psycopg2',
    },
    'host': {
        None: get_hostname(),
    },
    'port': {
        'mysql': '3306',
        'postgres': '5432',
    },
    'uri': {
        None: "{0}://{1}@{2}/{3}{4}",
        'sqlite': "{0}:///{5}",
    },
    'user': {
        'mysql': 'root',
        'postgresql': 'postgres',
    }
}


def get_default(key: str, dialect: str) -> str:
    """Return a default value for a given key and SQL dialect."""
    value = DEFAULT.get(key)
    return value.get(dialect, value.get(None))
