# -*- coding: utf-8 -*-

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'


def get_uri():
    dialect = DIALECT
    driver = DRIVER

    if driver:
        dialect = f"{dialect}+{driver}"

    user = config('MYSQL_USER')
    host = config('MYSQL_HOST')
    password = config('MYSQL_PASSWORD')

    if password:
        user = f"{user}:{password}"

    if host:
        user = f"{user}@{host}"

    return f"{dialect}://{user}/{SCHEMA}"
