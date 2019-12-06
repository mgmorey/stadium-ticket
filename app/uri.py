# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import os
import re
import urllib.parse

from decouple import config

CHARSET = {
    None: 'utf8',
    'mysql': 'utf8mb4',
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
    None: "{0}://{1}@{2}/{3}{4}",
    'sqlite': "{0}:///{5}",
}
USER = 'root'

PATTERN = {
    'DATABASE_CHARSET': re.compile(r'utf8(mb[34])?'),
    'DATABASE_DIALECT': re.compile(r'(mysql|sqlite)'),
    'DATABASE_DRIVER': re.compile(r'pymysql'),
    'DATABASE_HOST':
    re.compile(r'(\d{1,3}(\.\d{1,3}){3}|[a-z][a-z\d]+([\.-][a-z\d]+)*)'),
    'DATABASE_PASSWORD': re.compile(r'.*'),
    'DATABASE_PATHNAME': re.compile(r'(/?\.?[\w\d-]+)+'),
    'DATABASE_PORT': re.compile(r'\d{1,5}'),
    'DATABASE_SCHEMA': re.compile(r'[a-z\d-]+'),
    'DATABASE_USER': re.compile(r'[\w\d-]+'),
}


def _get_charset(dialect: str):
    """Return a database character set (encoding)."""
    if '{4}' not in URI.get(dialect, URI[None]):
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


def _get_dirname(vardir: str):
    """Return a database directory name (SQLite3 only)."""
    dirs = [vardir]
    home = os.getenv('HOME')

    if home:
        dirs.append(os.path.join(home, '.local'))
        dirs.append(home)

    dirs.append(os.getenv('TMPDIR', '.'))

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            break

    return dirname


def _get_endpoint(dialect: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in URI.get(dialect, URI[None]):
        return ''

    host = _get_string('DATABASE_HOST', default=HOST)
    port = _get_string('DATABASE_PORT', default=PORT.get(dialect))
    return f"{host}:{port}" if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{1}' not in URI.get(dialect, URI[None]):
        return ''

    password = _get_string('DATABASE_PASSWORD', default='')
    username = _get_string('DATABASE_USER', default='root')
    return (f"{username}:{urllib.parse.quote_plus(password)}"
            if password else username)


def _get_tuples(dialect: str):
    charset = _get_charset(dialect)
    return f"?charset={charset}" if charset else ''


def _get_pathname(dialect: str, schema: str, vardir: str):
    """Return a database filename (SQLite3 only)."""
    if '{5}' not in URI.get(dialect, URI[None]):
        return ''

    dirname = _get_dirname(vardir)
    filename = f"{schema}.sqlite"
    pathname = os.path.join(dirname, filename)
    return _get_string('DATABASE_PATHNAME', default=pathname)


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_string('DATABASE_DRIVER', default=_get_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_string(parameter: str, default: str):
    """Return a validated string parameter value."""
    value = config(parameter, default=default)

    if not value:
        value = default

    return _validate(parameter, value) if value else None


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    if not PATTERN[parameter].fullmatch(value):
        raise ValueError(f"Invalid {parameter} value: \"{value}\"")

    return value


def get_uri(schema: str, vardir: str):
    """Return a database connection URI string."""
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    endpoint = _get_endpoint(dialect)
    login = _get_login(dialect)
    pathname = _get_pathname(dialect, schema, vardir)
    scheme = _get_scheme(dialect)
    tuples = _get_tuples(dialect)
    uri = URI.get(dialect, URI[None])
    return uri.format(scheme, login, endpoint, schema, tuples, pathname)
