# -*- coding: utf-8 -*-

from decouple import config

DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'


def get_uri():
    host = config('MYSQL_HOST')
    user = config('MYSQL_USER')
    password = config('MYSQL_PASSWORD')

    if password:
        user = f'{user}:{password}'

    if host:
        user = f'{user}@{host}'

    return f"{DIALECT}+{DRIVER}://{user}/{SCHEMA}"
