# -*- coding: utf-8 -*-
"""Define methods to parse application configuration file."""

import configparser
import os

FILENAME = 'app.ini'


def _get_pathname(dirname: str):
    dirname = os.path.dirname(os.path.dirname(os.path.realpath(dirname)))
    pathname = os.path.join(dirname, FILENAME)
    return pathname


def get_config(dirname: str):
    """Return application configuration."""
    config = configparser.ConfigParser()
    pathname = _get_pathname(dirname)
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
