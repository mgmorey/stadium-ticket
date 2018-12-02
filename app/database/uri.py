# -*- coding: utf-8 -*-

import os

from decouple import config

DIALECT = 'mysql'
DRIVERS = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
USER = 'root'
PASSWORD = None
SCHEMA = 'stadium-tickets'
URIS = {
}


def _default_driver(dialect: str):
    driver = DRIVERS.get(dialect)
    return driver.format(dialect) if driver else None


def _default_uri(dialect: str):
    return URIS.get(dialect, "{0}://{1}@{2}/{3}")


def _get_credentials():
    password = config('DATABASE_PASSWORD', default=PASSWORD)
    user = config('DATABASE_USER', default=os.getenv('USER', 'root'))
    return f"{user}:{password}" if password else user


def _get_scheme(dialect: str):
    driver = config('DATABASE_DRIVER', default=_default_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_uri(dialect: str, credentials: str, host: str, schema: str):
    uri = config('DATABASE_URI', default=_default_uri(dialect))
    return uri.format(_get_scheme(dialect), credentials, host, schema)


def get_uri():
    credentials = _get_credentials()
    dialect = config('DATABASE_DIALECT', default=DIALECT)
    host = config('DATABASE_HOST', default=HOST)
    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    return _get_uri(dialect, credentials, host, schema)


if __name__ == '__main__':
    print("URI: {}".format(get_uri()))
