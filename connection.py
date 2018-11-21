# -*- coding: utf-8 -*-

import os

CONNECTION = "{0}+{1}://{2}:{3}@{4}/{5}"
DIALECT = 'mysql'
DRIVER = 'pymysql'
HOST = 'localhost'
SCHEMA = 'stadium-tickets'


def get_connection():
    return CONNECTION.format(DIALECT, DRIVER,
                             os.getenv('MYSQL_USER', os.getenv('USER')),
                             os.getenv('MYSQL_PASSWORD'),
                             os.getenv('MYSQL_HOST', HOST),
                             SCHEMA)
