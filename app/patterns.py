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

"""Represent a dicionary of regular expressions keyed by parameter."""

import re

PATTERN_CHARSET = r'utf8(mb[34])?'
PATTERN_DIALECT = r'(mysql|postgresql|sqlite)'
PATTERN_DRIVER = r'(pymysql|psycopg2)'
PATTERN_HOST = r'(\d{1,3}(\.\d{1,3}){3}|[a-z][a-z\d]+([\.-][a-z\d]+)*)'
PATTERN_PASSWORD = r'[^\x00-\x1F]{8,31}'
PATTERN_PATHNAME = r'(C:)?([/\\]?\.?[\w\d-]+)+'
PATTERN_PORT = r'\d{1,5}'
PATTERN_USER = r'\w[\w\d-]{0,30}'

PATTERN = {
    'charset': re.compile(PATTERN_CHARSET),
    'dialect': re.compile(PATTERN_DIALECT),
    'driver': re.compile(PATTERN_DRIVER),
    'host': re.compile(PATTERN_HOST),
    'password': re.compile(PATTERN_PASSWORD),
    'pathname': re.compile(PATTERN_PATHNAME),
    'port': re.compile(PATTERN_PORT),
    'user': re.compile(PATTERN_USER),
}


def get_pattern(key: str):
    """Return a compiled regular expression given a key."""
    return PATTERN[key]
