# -*- coding: utf-8 -*-

from decouple import config

CONNECTION = "{0}+{1}://{2}/{3}"
DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'


def get_uri():
    host = config('MYSQL_HOST')
    user = config('MYSQL_USER')
    password = config('MYSQL_PASSWORD')
    creds = user

    if password:
        creds = ':'.join([creds, password])

    if host:
        creds = '@'.join([creds, host])

    return CONNECTION.format(DIALECT, DRIVER, creds, SCHEMA)
