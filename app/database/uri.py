# -*- coding: utf-8 -*-

import os

from decouple import config

DRIVER = {
    'mysql': 'py{0}'
}
HOST = 'localhost'
USER = 'root'
SCHEMA = 'stadium-tickets'
URI = {
    'sqlite': "{0}:////tmp/{3}.db",
    None: "{0}://{1}@{2}/{3}"
}


def _get_driver(dialect: str):
    driver = DRIVER.get(dialect)
    return driver.format(dialect) if driver else None


def _get_host(dialect: str):
    if dialect == 'sqlite':
        return None

    return config('DATABASE_HOST', default=HOST)


def _get_login(dialect: str):
    if dialect == 'sqlite':
        return None

    password = config('DATABASE_PASSWORD')
    user = config('DATABASE_USER', default=os.getenv('USER', USER))
    return f"{user}:{password}" if password else user


def _get_scheme(dialect: str):
    driver = config('DATABASE_DRIVER', default=_get_driver(dialect))
    return f"{dialect}+{driver}" if driver else dialect


def _get_uri(dialect: str):
    return URI.get(dialect, URI[None])


def get_uri():
    dialect = config('DATABASE_DIALECT')
    schema = config('DATABASE_SCHEMA', default=SCHEMA)
    s = config('DATABASE_URI', default=_get_uri(dialect))
    return s.format(_get_scheme(dialect),
                    _get_login(dialect),
                    _get_host(dialect),
                    schema)


if __name__ == '__main__':
    print(get_uri())
