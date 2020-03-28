# -*- coding: utf-8 -*-
"""Represent a dicionary of regular expressions keyed by parameter."""

import re

REGEX_CHARSET = r'utf8(mb[34])?'
REGEX_DIALECT = r'(mysql|postgresql|sqlite)'
REGEX_DRIVER = r'(pymysql|psycopg2)'
REGEX_HOST = r'(\d{1,3}(\.\d{1,3}){3}|[a-z][a-z\d]+([\.-][a-z\d]+)*)'
REGEX_PASSWORD = r'.*'
REGEX_PATHNAME = r'(/?\.?[\w\d-]+)+'
REGEX_PORT = r'\d{1,5}'
REGEX_SCHEMA = r'[a-z\d-]+'
REGEX_USER = r'[\w\d-]+'

REGEX = {
    'charset': re.compile(REGEX_CHARSET),
    'dialect': re.compile(REGEX_DIALECT),
    'driver': re.compile(REGEX_DRIVER),
    'host': re.compile(REGEX_HOST),
    'password': re.compile(REGEX_PASSWORD),
    'pathname': re.compile(REGEX_PATHNAME),
    'port': re.compile(REGEX_PORT),
    'schema': re.compile(REGEX_SCHEMA),
    'user': re.compile(REGEX_USER),
}


def get_pattern(parameter: str):
    """Return a compiled regular expression given a parameter name."""
    return REGEX[parameter]
