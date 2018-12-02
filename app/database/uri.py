# -*- coding: utf-8 -*-

import os

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
HOST = 'mysql'
USER = os.getenv('USER')
PASSWORD = ''
SCHEMA = 'stadium-tickets'
URI = "{0}://{1}/{2}"
URIS = {
}

def get_uri():
    dialect = config('DATABASE_DIALECT', default=DIALECT)
    driver = config('DATABASE_DRIVER', default=DRIVER)
    hostname = config('DATABASE_HOST', default=HOST)
    username = config('DATABASE_USER', default=USER)
    password = config('DATABASE_PASSWORD', default=PASSWORD)

    if driver:
        dialect = f"{dialect}+{driver}"

    if password:
        username = f"{username}:{password}"

    if hostname:
        username = f"{username}@{hostname}"

    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    uri = config('DATABASE_URI', default=URIS.get(schema, URI))
    return uri.format(dialect, username, schema)
