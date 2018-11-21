# -*- coding: utf-8 -*-

import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session

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


engine = create_engine(get_connection())
session = scoped_session(sessionmaker(bind=engine))

Base = declarative_base()
Base.metadata.bind = engine
