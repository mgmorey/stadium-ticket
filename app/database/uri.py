# -*- coding: utf-8 -*-

import os

from decouple import config

DIALECT = 'mysql'
DRIVERS = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
USER = 'root'
PASSWORD = ''
SCHEMA = 'stadium-tickets'
URIS = {
}

def _default_driver(dialect: str):
    driver = DRIVERS.get(dialect)
    return driver.format(dialect) if driver else None

def _default_format(dialect: str):
    return URIS.get(dialect, "{0}://{1}/{2}")

def _default_user():
    return os.getenv('USER', 'root')

def get_uri():
    dialect = config('DATABASE_DIALECT', default=DIALECT)
    driver = config('DATABASE_DRIVER', default=_default_driver(dialect))
    hostname = config('DATABASE_HOST', default=HOST)
    username = config('DATABASE_USER', default=_default_user())
    password = config('DATABASE_PASSWORD', default=PASSWORD)
    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    uri = config('DATABASE_URI', default=_default_format(dialect))

    if driver:
        dialect = f"{dialect}+{driver}"

    if password:
        username = f"{username}:{password}"

    if hostname:
        username = f"{username}@{hostname}"

    return uri.format(dialect, username, schema)
