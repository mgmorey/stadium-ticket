# -*- coding: utf-8 -*-
"""Represent a dicionary of regular expressions keyed by parameter."""

import re

REGEX_CHARSET = r'utf8(mb[34])?'
REGEX_DIALECT = r'(mysql|sqlite)'
REGEX_DRIVER = r'pymysql'
REGEX_HOST = r'(\d{1,3}(\.\d{1,3}){3}|[a-z][a-z\d]+([\.-][a-z\d]+)*)'
REGEX_PASSWORD = r'.*'
REGEX_PATHNAME = r'(/?\.?[\w\d-]+)+'
REGEX_PORT = r'\d{1,5}'
REGEX_SCHEMA = r'[a-z\d-]+'
REGEX_USER = r'[\w\d-]+'

REGEX = {
    'DATABASE_CHARSET': re.compile(REGEX_CHARSET),
    'DATABASE_DIALECT': re.compile(REGEX_DIALECT),
    'DATABASE_DRIVER': re.compile(REGEX_DRIVER),
    'DATABASE_HOST': re.compile(REGEX_HOST),
    'DATABASE_PASSWORD': re.compile(REGEX_PASSWORD),
    'DATABASE_PATHNAME': re.compile(REGEX_PATHNAME),
    'DATABASE_PORT': re.compile(REGEX_PORT),
    'DATABASE_SCHEMA': re.compile(REGEX_SCHEMA),
    'DATABASE_USER': re.compile(REGEX_USER),
}


def get_pattern(parameter: str):
    """Return a compiled regular expression given a parameter name."""
    return REGEX[parameter]