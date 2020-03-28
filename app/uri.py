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
PREFIX = 'database'
URI = {
    None: "{0}://{1}@{2}/{3}{4}",
    'sqlite': "{0}:///{5}",
}
USERNAME = {
    'mysql': 'root',
    'postgresql': 'postgres',
}


def _get_charset(dialect: str):
    """Return a database character set (encoding)."""
    if '{4}' not in URI.get(dialect, URI[None]):
        return None

    return _get_string('charset', default=CHARSET.get(dialect))


def _get_driver(dialect: str):
    """Return a database URI driver parameter default value."""
    return _get_string('driver', default=DRIVER.get(dialect))


def _get_dirname(app_config):
    """Return a database directory name (SQLite3 only)."""
    dirs = []
    home = os.getenv('HOME')
    tmpdir = os.getenv('TMPDIR')

    if not _is_development():
        flask_datadir = FLASK_DATADIR.get(sys.platform, FLASK_DATADIR[None])
        dirs.append(os.path.join(flask_datadir, app_config['name']))

    if home:
        dirs.append(os.path.join(home, '.local', 'share'))
        dirs.append(home)

    if tmpdir:
        dirs.append(tmpdir)

    dirs.append(os.path.join(os.path.sep, 'tmp'))

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            return dirname

    return ''


def _get_endpoint(dialect: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in URI.get(dialect, URI[None]):
        return ''

    host = _get_string('host', default=HOST)
    port = _get_string('port', default=PORT.get(dialect))
    return ':'.join([host, port]) if port else host


def _get_login(dialect: str):
    """Return a database URI login parameter value."""
    if '{1}' not in URI.get(dialect, URI[None]):
        return ''

    password = _get_string('password', default='')
    username = _get_string('user', default=USERNAME.get(dialect))
    return (':'.join([username, urllib.parse.quote_plus(password)])
            if password else username)


def _get_pathname(dialect: str, schema: str, app_config):
    """Return a database filename (SQLite3 only)."""
    if '{5}' not in URI.get(dialect, URI[None]):
        return ''

    dirname = _get_dirname(app_config)
    filename = '.'.join([schema, dialect])
    pathname = os.path.join(dirname, filename)
    return _get_string('pathname', default=pathname)


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_string('driver', default=_get_driver(dialect))
    return '+'.join([dialect, driver]) if driver else dialect


def _get_string(parameter: str, default: str, dialect: str = None):
    """Return a validated string parameter value."""
    prefix = dialect[:8] if dialect else PREFIX
    string = '_'.join([prefix, parameter]).upper()
    value = decouple.config(string, default=default)

    if not value:
        value = default

    return _validate(parameter, value) if value else None


def _get_tuples(dialect: str):
    charset = _get_charset(dialect)
    return "?charset={}".format(charset) if charset else ''


def get_uri(app_config):
    """Return a database connection URI string."""
    dialect = _get_string('dialect', default=DIALECT)
    pathname = _get_pathname(dialect, app_config['schema'], app_config)
    uri_format = URI.get(dialect, URI[None])
    return uri_format.format(_get_scheme(dialect),
                             _get_login(dialect),
                             _get_endpoint(dialect),
                             app_config['schema'],
                             _get_tuples(dialect),
                             pathname)


def _is_development():
    return (os.getenv('FLASK_ENV', 'production') == 'development' or
            os.getenv('WERKZEUG_RUN_MAIN', 'false') == 'true')


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    if not get_pattern(parameter).fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(parameter, value))

    return value
