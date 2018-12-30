# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import os
import re

from decouple import config

DIALECT = 'sqlite'
DRIVER = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
SCHEMA = 'stadium-tickets'
URI = {
    'sqlite': "{0}:////tmp/{1}.db",
    None: "{0}://{3}@{2}/{1}"
}
USER = 'root'

PATTERN = {
    'DATABASE_HOST': re.compile(r'[\w\d\-\.]+'),
    'DATABASE_PASSWORD': re.compile(r'[\w\d\-\.!\#\$\^&\*\=\+]+'),
    'DATABASE_PORT': re.compile(r'([\d]+|[\w-]+)'),
    None: re.compile(r'[\w\d\-]+')
}


def _get_driver(dialect: str):
    """Return a database URI driver parameter value."""
    driver = DRIVER.get(dialect)
    return driver.format(dialect) if driver else None


def _get_endpoint(dialect: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in _get_uri(dialect):
        return None

    host = _get_string('DATABASE_HOST', default=HOST)
    port = _get_string('DATABASE_PORT')
    return f"{host}:{port}" if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{3}' not in _get_uri(dialect):
        return None

    password = _get_string('DATABASE_PASSWORD')
    user = _get_string('DATABASE_USER', default=os.getenv('USER', USER))
    return f"{user}:{password}" if password else user


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_string('DATABASE_DRIVER', default=_get_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_string(parameter: str, default: str = None):
    """Return a validated string parameter value."""
    value = config(parameter, default=default)
    return None if value is None else _validate_string(parameter, value)


def _get_uri(dialect: str):
    """Return a database URI format specifier."""
    return URI.get(dialect, URI[None])


def _validate_string(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    pattern = PATTERN.get(parameter, PATTERN[None])

    if not pattern.fullmatch(value):
        raise ValueError(f"Invalid {parameter} value: \"{value}\"")

    return value


def get_uri():
    """Return a database connection URI string."""
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    scheme = _get_scheme(dialect)
    schema = _get_string('DATABASE_SCHEMA', default=SCHEMA)
    endpoint = _get_endpoint(dialect)
    login = _get_login(dialect)
    uri = config('DATABASE_URI', default=_get_uri(dialect))
    return uri.format(scheme, schema, endpoint, login)
