# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import os
import sys
import urllib.parse

import decouple

from .pattern import get_pattern

CHARSET = {
    'mysql': 'utf8mb4',
}
DIALECT = 'sqlite'
DRIVER = {
    'mysql': 'pymysql',
    'postgresql': 'psycopg2',
}
FLASK_DATADIR = {
    None: os.path.join(os.path.sep, 'var', 'opt'),
    'darwin': os.path.join(os.path.sep, 'usr', 'local', 'var', 'opt'),
}
HOST = 'localhost'
PORT = {
    'mysql': '3306',
    'postgres': '5432',
}
URI = {
    None: "{0}://{1}@{2}/{3}{4}",
    'sqlite': "{0}:///{5}",
}
USER = 'root'


def _get_charset(dialect: str):
    """Return a database character set (encoding)."""
    if '{4}' not in URI.get(dialect, URI[None]):
        return None

    return _get_string('DATABASE_CHARSET', default=CHARSET.get(dialect))


def _get_driver(dialect: str):
    """Return a database URI driver parameter default value."""
    return _get_string('DATABASE_DRIVER', default=DRIVER.get(dialect))


def _get_dirname(app_config):
    """Return a database directory name (SQLite3 only)."""
    dirs = []
    home = os.getenv('HOME')
    tmpdir = os.getenv('TMPDIR', '.')

    if _is_production():
        flask_datadir = FLASK_DATADIR.get(sys.platform, FLASK_DATADIR[None])
        dirs.append(os.path.join(flask_datadir, app_config['name']))
    elif home:
        dirs.append(os.path.join(home, '.local', 'share'))
        dirs.append(home)

    dirs.append(tmpdir)

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            return dirname

    return None


def _get_endpoint(dialect: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in URI.get(dialect, URI[None]):
        return ''

    host = _get_string('DATABASE_HOST', default=HOST)
    port = _get_string('DATABASE_PORT', default=PORT.get(dialect))
    return ':'.join([host, port]) if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{1}' not in URI.get(dialect, URI[None]):
        return ''

    password = _get_string('DATABASE_PASSWORD', default='')
    username = _get_string('DATABASE_USER', default='root')
    return (':'.join([username, urllib.parse.quote_plus(password)])
            if password else username)


def _get_pathname(dialect: str, schema: str, app_config):
    """Return a database filename (SQLite3 only)."""
    if '{5}' not in URI.get(dialect, URI[None]):
        return ''

    dirname = _get_dirname(app_config)
    filename = '.'.join([schema, dialect])
    pathname = os.path.join(dirname, filename)
    return _get_string('DATABASE_PATHNAME', default=pathname)


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_string('DATABASE_DRIVER', default=_get_driver(dialect))
    return '+'.join([dialect, driver]) if driver else dialect


def _get_string(parameter: str, default: str):
    """Return a validated string parameter value."""
    value = decouple.config(parameter, default=default)

    if not value:
        value = default

    return _validate(parameter, value) if value else None


def _get_tuples(dialect: str):
    charset = _get_charset(dialect)
    return "?charset={}".format(charset) if charset else ''


def get_uri(app_config):
    """Return a database connection URI string."""
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    pathname = _get_pathname(dialect, app_config['schema'], app_config)
    uri_format = URI.get(dialect, URI[None])
    return uri_format.format(_get_scheme(dialect),
                             _get_login(dialect),
                             _get_endpoint(dialect),
                             app_config['schema'],
                             _get_tuples(dialect),
                             pathname)


def _is_production():
    return (os.getenv('FLASK_ENV', 'production') == 'production' and
            os.getenv('WERKZEUG_RUN_MAIN', 'false') == 'false')


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    if not get_pattern(parameter).fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(parameter, value))

    return value
