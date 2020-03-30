# -*- coding: utf-8 -*-
"""Represent a dicionary of defaults keyed by parameter and SQL
dialect."""

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
        None: 'localhost',
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
