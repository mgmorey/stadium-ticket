# -*- coding: utf-8 -*-

import os

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
HOST = 'mysql'
USER = os.getenv('USER')
PASSWORD = ''
SCHEMA = 'stadium-tickets'


def get_uri():
    default_user = config('MYSQL_USER', default=USER)
    default_host = config('MYSQL_HOST', default=HOST)
    default_password = config('MYSQL_PASSWORD', default=PASSWORD)
    dialect = config('DATABASE_DIALECT', default=DIALECT)
    driver = config('DATABASE_DRIVER', default=DRIVER)
    host = config('DATABASE_HOST', default=default_host)
    user = config('DATABASE_USER', default=default_user)
    password = config('DATABASE_PASSWORD', default_password)

    if driver:
        dialect = f"{dialect}+{driver}"

    if password:
        user = f"{user}:{password}"

    if host:
        user = f"{user}@{host}"

    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    return f"{dialect}://{user}/{schema}"
