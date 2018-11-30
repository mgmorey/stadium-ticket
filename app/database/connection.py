# -*- coding: utf-8 -*-

from decouple import config
import os

CONNECTION = "{0}+{1}://{2}/{3}"
DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'


def get_connection():
    host = config('MYSQL_HOST')
    user = config('MYSQL_USER')
    password = config('MYSQL_PASSWORD')

    if password:
        credentials = ':'.join([user, password])
    else:
        credentials = user

    if host:
        credentials = '@'.join([credentials, host])

    return CONNECTION.format(DIALECT, DRIVER, credentials, SCHEMA)
