# -*- coding: utf-8 -*-
"""Define methods to construct a SQLAlchemy database URI string."""

import configparser
import urllib.parse

import decouple

from .datafile import get_datafile
from .default import get_default
from .pattern import get_pattern

PREFIX = 'database'


def _get_charset(dialect: str, uri: str):
    """Return a database character set (encoding)."""
    if '{4}' not in uri:
        return None

    return _get_valid('charset', dialect)


def _get_driver(dialect: str):
    """Return a database URI driver parameter default value."""
    return _get_valid('driver', dialect)


def _get_endpoint(dialect: str, uri: str):
    """Return a database URI endpoint parameter value."""
    if '{2}' not in uri:
        return ''

    host = _get_valid('host', dialect)
    port = _get_valid('port', dialect)
    return ':'.join([host, port]) if port else host


def _get_login(dialect: str, uri: str):
    """Return a database URI login parameter value."""
    if '{1}' not in uri:
        return ''

    password = _get_valid('password', dialect, '')
    quotedpw = urllib.parse.quote_plus(password)
    username = _get_valid('user', dialect)
    return ':'.join([username, quotedpw]) if password else username


def _get_parameter(prefix: str, suffix: str):
    """Return a parameter name given a prefix and suffix."""
    return '_'.join([prefix, suffix]).upper()


def _get_pathname(config: configparser.ConfigParser, dialect: str, uri: str):
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


def _get_scheme(dialect: str):
    """Return a database URI scheme parameter value."""
    driver = _get_valid('driver', dialect)
    return '+'.join([dialect, driver]) if driver else dialect


def _get_tuples(dialect: str, uri: str):
    """Return tuples formatted as query parameters."""
    charset = _get_charset(dialect, uri)
    return "?charset={}".format(charset) if charset else ''


def _get_valid(suffix: str, dialect: str, default: str = None):
    """Return a validated string parameter value."""
    value = _get_value(suffix, dialect, default)

    if value is None:
        return None

    return _validate(suffix, value)


def _get_value(suffix: str, dialect: str, default: str = None):
    """Return a string parameter value."""
    if default is None:
        default = get_default(suffix, dialect)

    parameters = [_get_parameter(prefix, suffix) for prefix in
                  _get_prefixes(dialect)]
    return decouple.config(parameters[0],
                           default=(decouple.config(parameters[1],
                                                    default=default) if
                                    len(parameters) > 1 else
                                    default))


def get_uri(config: configparser.ConfigParser):
    """Return a database connection URI string."""
    dialect = _get_valid('dialect', None)
    uri = get_default('uri', dialect)
    return uri.format(_get_scheme(dialect),
                      _get_login(dialect, uri),
                      _get_endpoint(dialect, uri),
                      config['database']['instance'],
                      _get_tuples(dialect, uri),
                      _get_pathname(config, dialect, uri))


def _validate(parameter: str, value: str) -> str:
    """Raise a ValueError if parameter value is invalid."""
    if not get_pattern(parameter).fullmatch(value):
        raise ValueError("Invalid {} value: \"{}\"".format(parameter, value))

    return value
