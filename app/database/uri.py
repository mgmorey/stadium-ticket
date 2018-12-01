# -*- coding: utf-8 -*-

import os

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
HOST = 'mysql'
USER = os.getenv('USER')
SCHEMA = 'stadium-tickets'


def get_uri():
    dialect = config('DATABASE_DIALECT', default=DIALECT)
    driver = config('DATABASE_DRIVER', default=DRIVER)

    if driver:
        dialect = f"{dialect}+{driver}"

    user = config('DATABASE_USER', default=config('MYSQL_USER', default=USER))
    host = config('DATABASE_HOST', default=config('MYSQL_HOST', default=HOST))
    password = config('DATABASE_PASSWORD', default=config('MYSQL_PASSWORD'))

    if password:
        user = f"{user}:{password}"

    if host:
        user = f"{user}@{host}"

    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    return f"{dialect}://{user}/{schema}"
