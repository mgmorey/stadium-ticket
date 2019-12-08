# -*- coding: utf-8 -*-
"""Define methods to parse application configuration file."""

import configparser
import os

FILENAME = 'app.ini'


def _get_dirname(pathname: str):
    if os.path.isfile(pathname):
        return os.path.dirname(pathname)

    return pathname


def _get_pathname(pathname: str, filename: str):
    dirname = _get_dirname(pathname)
    pathname = os.path.join(dirname, filename)

    if os.path.exists(pathname):
        return pathname

    dirname = os.path.dirname(dirname)
    return _get_pathname(dirname, filename)


def get_config(filename: str, section: str = None):
    """Return application configuration."""
    if not section:
        section = 'app'

    pathname = _get_pathname(os.path.realpath(__file__), filename)
    config = configparser.ConfigParser()
    config.read(pathname)
    return config[section]
