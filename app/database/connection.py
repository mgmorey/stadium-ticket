# -*- coding: utf-8 -*-

import os

CONNECTION = "{0}+{1}://{2}/{3}"
DIALECT = 'mysql'
DRIVER = 'pymysql'
SCHEMA = 'stadium-tickets'

HOST = 'localhost'
USER = 'root'


def get_connection():
    host = os.getenv('MYSQL_HOST', HOST)
    user = os.getenv('MYSQL_USER', USER)
    password = os.getenv('MYSQL_PASSWORD')

    if password:
        credentials = ':'.join([user, password])
    else:
        credentials = user

    if host:
        credentials = '@'.join([credentials, host])

    return CONNECTION.format(DIALECT, DRIVER, credentials, SCHEMA)
