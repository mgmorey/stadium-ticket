# -*- coding: utf-8 -*-
"""Represent a dicionary of regular expressions keyed by parameter."""

import re

PATTERN_CHARSET = r'utf8(mb[34])?'
PATTERN_DIALECT = r'(mysql|postgresql|sqlite)'
PATTERN_DRIVER = r'(pymysql|psycopg2)'
PATTERN_HOST = r'(\d{1,3}(\.\d{1,3}){3}|[a-z][a-z\d]+([\.-][a-z\d]+)*)'
PATTERN_PASSWORD = r'.*'
PATTERN_PATHNAME = r'(/?\.?[\w\d-]+)+'
PATTERN_PORT = r'\d{1,5}'
PATTERN_USER = r'[\w\d-]+'

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
