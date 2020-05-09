# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import configparser
import urllib.parse

import decouple

from .datafile import get_datafile
from .defaults import get_default
from .patterns import get_pattern

PREFIX = 'database'


def _get_charset(dialect: str, uri: str) -> str:
    """Return a database character set (encoding)."""
    if '{4}' not in uri:
        return None

    return _get_valid('charset', dialect)


def _get_driver(dialect: str) -> str:
    """Return a database URI driver parameter default value."""
    return _get_valid('driver', dialect)


def _get_endpoint(dialect: str, uri: str) -> str:
    """Return a database URI endpoint parameter value."""
    if '{2}' not in uri:
        return ''

    host = _get_valid('host', dialect)
    port = _get_valid('port', dialect)
    return ':'.join([host, port]) if port else host


def _get_login(dialect: str, uri: str) -> str:
    """Return a database URI login parameter value."""
    if '{1}' not in uri:
        return ''

    user = _get_valid('user', dialect)
    password = _get_valid('password', dialect, '')
    return ':'.join([user, _quote(password)]) if password else user


def _get_parameter(prefix: str, suffix: str) -> str:
    """Return a parameter name given a prefix and suffix."""
    return '_'.join([prefix, suffix]).upper()


def _get_parameters(suffix: str, dialect: str) -> list:
    """Return a list of parameters given a prefix and SQL dialect."""
    return [_get_parameter(prefix, suffix) for prefix in
            _get_prefixes(dialect)]


def _get_pathname(config: configparser.ConfigParser,
                  dialect: str,
                  uri: str) -> str:
    """Return a database pathname."""
    if '{5}' not in uri:
        return ''

    return _get_valid('pathname', dialect, get_datafile(config, dialect))


def _get_prefixes(dialect: str):
    """Return a list of parameter prefixes."""
    prefixes = [PREFIX]

    if dialect is not None:
        prefixes.append(dialect[:8])

    return prefixes


def _get_scheme(dialect: str) -> str:
    """Return a database URI scheme parameter value."""
    driver = _get_valid('driver', dialect)
    return '+'.join([dialect, driver]) if driver else dialect


def _get_tuples(dialect: str, uri: str) -> str:
    """Return tuples formatted as query parameters."""
    charset = _get_charset(dialect, uri)
    return "?charset={}".format(charset) if charset else ''


def _get_valid(key: str, dialect: str = None, default: str = None) -> str:
    """Return a validated string parameter value."""
    value = _get_value(key, dialect, default)

    if not value:
        return None

    return _validate(key, value)


def _get_value(key: str, dialect: str = None, default: str = None) -> str:
    """Return a string parameter value."""
    if default is None:
        default = get_default(key, dialect)

    for parameter in _get_parameters(key, dialect):
        value = decouple.config(parameter, default=default)

        if value:
            return value

    return default


def get_uri(config: configparser.ConfigParser) -> str:
    """Return a database connection URI string."""
    dialect = _get_valid('dialect')
    fmt = get_default('uri', dialect)
    uri = fmt.format(_get_scheme(dialect),
                     _get_login(dialect, fmt),
                     _get_endpoint(dialect, fmt),
                     config['database']['instance'],
                     _get_tuples(dialect, fmt),
                     _get_pathname(config, dialect, fmt))
    return uri


def _quote(password: str) -> str:
    return urllib.parse.quote_plus(password)


def _validate(key: str, value: str) -> str:
    """Raise a ValueError if a given value is invalid."""
    if not get_pattern(key).fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(key, value))

    return value
