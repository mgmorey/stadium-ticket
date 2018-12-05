# -*- coding: utf-8 -*-

import os

from decouple import config

DRIVER = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
USER = 'root'
SCHEMA = 'stadium-tickets'
URI = {
    'sqlite': "{0}:////tmp/{1}.db",
    None: "{0}://{3}@{2}/{1}"
}


def _get_config(parameter: str, default: str = None):
    value = config(parameter, default=default)
    return value


def _get_driver(dialect: str):
    driver = DRIVER.get(dialect)
    return driver.format(dialect) if driver else None


def _get_hostname(dialect: str):
    if '{2}' not in _get_uri(dialect):
        return None

    return config('DATABASE_HOST', default=HOST)


def _get_login(dialect: str):
    if '{3}' not in _get_uri(dialect):
        return None

    password = _get_config('DATABASE_PASSWORD')
    user = _get_config('DATABASE_USER', default=os.getenv('USER', USER))
    return f"{user}:{password}" if password else user


def _get_scheme(dialect: str):
    driver = _get_config('DATABASE_DRIVER', default=_get_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_uri(dialect: str):
    return URI.get(dialect, URI[None])


def get_uri():
    dialect = _get_config('DATABASE_DIALECT')
    schema = _get_config('DATABASE_SCHEMA', default=SCHEMA)
    uri = _get_config('DATABASE_URI', default=_get_uri(dialect))
    return uri.format(_get_scheme(dialect), schema,
                      _get_hostname(dialect),
                      _get_login(dialect))


if __name__ == '__main__':
    print(get_uri())
