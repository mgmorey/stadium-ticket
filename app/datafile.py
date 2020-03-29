# -*- coding: utf-8 -*-
"""Define methods to generate a database file pathname."""

import configparser
import os
import sys

FLASK_DATADIR = {
    None: os.path.join(os.path.sep, 'var', 'opt'),
    'darwin': os.path.join(os.path.sep, 'usr', 'local', 'var', 'opt'),
}


def get_datafile(config: configparser.ConfigParser, dialect: str):
    """Return the default database pathname."""
    dirname = _get_dirname(config['app']['name'])
    instance = config['database']['instance']
    filename = '.'.join([instance, dialect])
    return os.path.join(dirname, filename)


def _get_dirname(app_name: str):
    """Return a database directory name."""
    dirs = []
    home = os.getenv('HOME')
    tmpdir = os.getenv('TMPDIR')

    if not _is_development():
        flask_datadir = FLASK_DATADIR.get(sys.platform, FLASK_DATADIR[None])
        dirs.append(os.path.join(flask_datadir, app_name))

    if home:
        dirs.append(os.path.join(home, '.local', 'share'))
        dirs.append(home)

    if tmpdir:
        dirs.append(tmpdir)

    dirs.append(os.path.join(os.path.sep, 'tmp'))

    for dirname in dirs:
        if os.access(dirname, os.W_OK):
            return dirname

    return ''


def _is_development():
    """Return true if running in a development environment."""
    return (os.getenv('FLASK_ENV', 'production') == 'development' or
            os.getenv('WERKZEUG_RUN_MAIN', 'false') == 'true')
