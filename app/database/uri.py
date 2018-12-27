# -*- coding: utf-8 -*-

import os

from decouple import config

from .validate import validate_string

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


def _get_driver(dialect: str):
    driver = DRIVER.get(dialect)
    return driver.format(dialect) if driver else None


def _get_endpoint(dialect: str):
    if '{2}' not in _get_uri(dialect):
        return None

    host = _get_string('DATABASE_HOST', default=HOST)
    port = _get_string('DATABASE_PORT')
    return f"{host}:{port}" if port else host


def _get_login(dialect: str):
    if '{3}' not in _get_uri(dialect):
        return None

    password = _get_string('DATABASE_PASSWORD')
    user = _get_string('DATABASE_USER', default=os.getenv('USER', USER))
    return f"{user}:{password}" if password else user


def _get_scheme(dialect: str):
    driver = _get_string('DATABASE_DRIVER', default=_get_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_string(parameter: str, default: str = None):
    value = config(parameter, default=default)
    return None if value is None else validate_string(parameter, value)


def _get_uri(dialect: str):
    return URI.get(dialect, URI[None])


def get_uri():
    dialect = _get_string('DATABASE_DIALECT', default=DIALECT)
    scheme = _get_scheme(dialect)
    schema = _get_string('DATABASE_SCHEMA', default=SCHEMA)
    endpoint = _get_endpoint(dialect)
    login = _get_login(dialect)
    uri = config('DATABASE_URI', default=_get_uri(dialect))
    return uri.format(scheme, schema, endpoint, login)
