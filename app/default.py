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
        'mysql': '127.0.0.1',
        'postgresql': 'localhost',
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


def get_default(suffix: str, dialect: str):
    """Return a default value for a given suffix and SQL dialect."""
    default = DEFAULT.get(suffix)
    return default.get(dialect, default.get(None))
