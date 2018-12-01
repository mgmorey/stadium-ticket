# -*- coding: utf-8 -*-

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'


def get_uri():
    host = config('MYSQL_HOST')
    password = config('MYSQL_PASSWORD')
    user = config('MYSQL_USER')

    if password:
        user = ':'.join([user, password])

    if host:
        user = '@'.join([user, host])

    return f"{DIALECT}+{DRIVER}://{user}/{SCHEMA}"
