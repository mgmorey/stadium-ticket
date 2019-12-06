# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import os
import re
import urllib.parse

from decouple import config

CHARSET = {
    'mysql': 'utf8mb4',
    None: 'utf8',
}
DIALECT = 'sqlite'
DRIVER = {
    'mysql': 'py{0}',
}
HOST = 'localhost'
PORT = {
    'mysql': '3306',
}
URI = {
    'mysql': "{0}://{3}@{2}/{1}?charset={4}",
    'sqlite': "{0}:///{5}",
}
USER = 'root'

PATTERN = {
    'DATABASE_CHARSET': re.compile(r'[\w\d]+'),
    'DATABASE_DIALECT': re.compile(r'(mysql|sqlite)'),
    'DATABASE_DRIVER': re.compile(r'pymysql'),
    'DATABASE_HOST': re.compile(r'[\w\d\-\.]+'),
    'DATABASE_PASSWORD': re.compile(r'.*'),
    'DATABASE_PATHNAME': re.compile(r'([/]?[\.]?[\w\d\-]+)+'),
    'DATABASE_PORT': re.compile(r'([\d]+|[\w-]+)'),
    'DATABASE_SCHEMA': re.compile(r'[\w\d\-]+'),
    'DATABASE_USER': re.compile(r'[\w\d\-]+'),
}


def _get_charset(dialect: str):
    """Return a database character set (encoding)."""
    if '{4}' not in URI.get(dialect):
        return ''

    charset = CHARSET.get(dialect, CHARSET[None])
    return _get_string('DATABASE_CHARSET', default=charset)


def _get_driver(dialect: str):
    """Return a database URI driver parameter default value."""
    return _get_string('DATABASE_DRIVER', default=_get_driver_default(dialect))


def _get_driver_default(dialect: str):
    """Return a database URI driver parameter value."""
    driver = DRIVER.get(dialect)
    return driver.format(dialect) if driver else None


def _get_endpoint(dialect: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in URI.get(dialect):
        return ''

    host = _get_string('DATABASE_HOST', default=HOST)
    port = _get_string('DATABASE_PORT', default=PORT.get(dialect))
    return "{}:{}".format(host, port) if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{3}' not in URI.get(dialect):
        return ''

    password = _get_string('DATABASE_PASSWORD', default='')
    username = _get_string('DATABASE_USER', default='root')
    return ("{}:{}".format(username, urllib.parse.quote_plus(password))
            if password else username)


def _get_pathname(dialect: str, schema: str, vardir: str):
    """Return a database filename (SQLite3 only)."""
    if '{5}' not in URI.get(dialect):
        return ''

    dirs = [vardir]
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


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    if not PATTERN[parameter].fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(parameter, value))

    return value


def get_uri(schema: str, vardir: str):
    """Return a database connection URI string."""
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    charset = _get_charset(dialect)
    endpoint = _get_endpoint(dialect)
    login = _get_login(dialect)
    pathname = _get_pathname(dialect, schema, vardir)
    scheme = _get_scheme(dialect)
    uri = URI.get(dialect)
    return uri.format(scheme, schema, endpoint, login, charset, pathname)
