# -*- coding: utf-8 -*-
"""Define methods to generate a datafile pathname."""

import configparser
import os
import sys

FLASK_DATADIR = {
    None: os.path.join(os.path.sep, 'var', 'opt'),
    'darwin': os.path.join(os.path.sep, 'usr', 'local', 'var', 'opt'),
}


def get_datafile(config: configparser.ConfigParser, dialect: str):
    """Return the default datafile pathname."""
    dirname = _get_dirname(config)
    filename = _get_filename(config, dialect)
    return os.path.join(dirname, filename)


def _get_dirname(config: configparser.ConfigParser):
    """Return the default datafile directory name."""
    dirs = []
    home_dir = os.getenv('HOME')
    temp_dir = os.getenv('TMPDIR')

    if not _is_development():
        dirs.append(os.path.join(_get_flask_datadir(), config['app']['name']))

    if home_dir is not None:
        dirs.append(os.path.join(home_dir, '.local', 'share'))
        dirs.append(home_dir)

    if temp_dir is not None:
        dirs.append(temp_dir)

    dirs.append(os.path.join(os.path.sep, 'tmp'))

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            return dirname

    return ''


def _get_filename(config: configparser.ConfigParser, dialect: str):
    """Return the default datafile filename."""
    instance = config['database']['instance']
    return '.'.join([instance, dialect])


def _get_flask_datadir():
    return FLASK_DATADIR.get(sys.platform, FLASK_DATADIR.get(None))


def _is_development():
    """Return true if Flask is running in a development environment."""
    return (os.getenv('FLASK_ENV', 'production') == 'development' or
            os.getenv('WERKZEUG_RUN_MAIN', 'false') == 'true')
