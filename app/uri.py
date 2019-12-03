# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import os
import re

from decouple import config

APP_NAME = 'stadium-ticket'
APP_SCHEMA = 'stadium-tickets'
APP_VARDIR = '/var/opt/{}'.format(APP_NAME)

DIALECT = 'sqlite'
DRIVER = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
PORT = {
    'mysql': '3306'
}
URI = {
    'sqlite': "{0}:///{4}",
    None: "{0}://{3}@{2}/{1}"
}
USER = 'root'

PATTERN = {
    'DATABASE_DIALECT': re.compile(r'[\w]+'),
    'DATABASE_PATHNAME': re.compile(r'[/]?[\w\d]+([/]?[\.]?[\w\d\-]+)*'),
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
    port = _get_string('DATABASE_PORT', default=PORT.get(dialect))
    return "{}:{}".format(host, port) if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{3}' not in _get_uri(dialect):
        return None

    password = _get_string('DATABASE_PASSWORD', default='')
    username = _get_string('DATABASE_USER', default='root')
    return "{}:{}".format(username, password) if password else username


def _get_pathname(dialect: str, schema: str):
    """Return a database filename (SQLite3 only)."""
    if '{4}' not in _get_uri(dialect):
        return None

    dirs = [APP_VARDIR]
    home = os.getenv('HOME')

    if home:
        dirs.append("{}/.local".format(home))
        dirs.append(home)

    dirs.append('/tmp')

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            break

    filename = "{}.sqlite".format(schema)
    pathname = os.path.join(dirname, filename)
    return _get_string('DATABASE_PATHNAME', default=pathname)


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_string('DATABASE_DRIVER', default=_get_driver(dialect))
    return "{}+{}".format(dialect, driver) if driver else dialect


def _get_string(parameter: str, default: str):
    """Return a validated string parameter value."""
    value = config(parameter, default=default)

    if not value:
        value = default

    return _validate(parameter, value) if value else None


def _get_uri(dialect: str):
    """Return a database URI format specifier."""
    return URI.get(dialect, URI[None])


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    pattern = PATTERN.get(parameter, PATTERN[None])

    if not pattern.fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(parameter, value))

    return value


def get_uri():
    """Return a database connection URI string."""
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    endpoint = _get_endpoint(dialect)
    login = _get_login(dialect)
    pathname = _get_pathname(dialect, APP_SCHEMA)
    scheme = _get_scheme(dialect)
    uri = _get_uri(dialect)
    return uri.format(scheme, APP_SCHEMA, endpoint, login, pathname)
