# -*- coding: utf-8 -*-
# Copyright (C) 2020  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""Define methods to parse application configuration file."""

import configparser
import os

FILENAME = 'app.ini'


def _get_dirname(pathname: str) -> str:
    """Return a directory name, given a directory or pathname."""
    if os.path.isfile(pathname):
        return os.path.dirname(pathname)

    return pathname


def _get_pathname(pathname: str, filename: str) -> str:
    """Return a pathname, given a directory or pathname and a filename."""
    dirname = _get_dirname(pathname)
    pathname = os.path.join(dirname, filename)

    if os.path.exists(pathname):
        return pathname

    dirname = os.path.dirname(dirname)
    return _get_pathname(dirname, filename)


def get_config(filename: str = None) -> configparser.ConfigParser:
    """Return application configuration as a ConfigParser object."""
    if not filename:
        filename = FILENAME

    pathname = _get_pathname(os.path.realpath(__file__), filename)
    config = configparser.ConfigParser()
    config.read(pathname)
    return config
