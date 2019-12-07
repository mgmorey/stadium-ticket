# -*- coding: utf-8 -*-
"""Define methods to parse application configuration file."""

import configparser
import os

FILENAME = 'app.ini'


def _get_dirname(pathname: str):
    if os.path.isfile(pathname):
        return os.path.dirname(pathname)

    return pathname


def _get_pathname(pathname: str):
    dirname = _get_dirname(pathname)
    pathname = os.path.join(dirname, FILENAME)

    if os.path.exists(pathname):
        return pathname

    return _get_pathname(os.path.dirname(dirname))


def get_config():
    """Return application configuration."""
    pathname = _get_pathname(os.path.realpath(__file__))
    config = configparser.ConfigParser()
    config.read(pathname)
    return config


def get_name(app_config):
    """Return application name."""
    return app_config['names']['name']


def get_schema(app_config):
    """Return application schema."""
    return app_config['names']['schema']


def get_vardir(app_config):
    """Return application data directory."""
    return app_config['names']['vardir']
