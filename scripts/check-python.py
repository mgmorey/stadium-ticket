#!/usr/bin/env python

# check-python-version: determine if Python version meets requirements
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

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

from __future__ import print_function
import os
import re
import sys

try:
    from configparser import ConfigParser, NoOptionError, NoSectionError
except ImportError:
    from ConfigParser import ConfigParser, NoOptionError, NoSectionError

INPUT = 'Pipfile'

PYTHON_VERSION_LEN = 3
PYTHON_VERSION_PATH = ['requires', 'python_version']
PYTHON_VERSION_REGEX = r'^(\d{1,3}(\.\d{1,3}){0,2})$'

QUOTED_REGEX = r'^"([^"]+)"$'


class ParseError(Exception):
    pass


def compare_versions(s1, s2):
    return compute_scalar_version(s1) - compute_scalar_version(s2)


def compute_scalar_version(s):
    result = 0
    v = s.split('.')

    for i in range(PYTHON_VERSION_LEN):
        result *= 1000
        result += int(v[i]) if i < len(v) else 0

    return result


def get_minimum_version():
    config = ConfigParser()
    path = get_pipfile()
    config.read(path)

    try:
        return parse_version(unquote(config.get(PYTHON_VERSION_PATH[0],
                                                PYTHON_VERSION_PATH[1])))
    except (NoOptionError, NoSectionError, ParseError) as e:
        raise ParseError("{}: Unable to parse: {}".format(path, e))


def get_pipfile():
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    source_dir = os.path.dirname(script_dir)
    return os.path.join(source_dir, INPUT)


def parse_version(s):
    try:
        return re.search(PYTHON_VERSION_REGEX, s).group(1)
    except AttributeError as e:
        raise ParseError("Invalid version string '{}'".format(s))


def unquote(s):
    try:
        return re.search(QUOTED_REGEX, s).group(1)
    except AttributeError as e:
        raise ParseError("Invalid quoted string '{}'".format(s))


def main():
    if len(sys.argv) > 2:
        s = "{}: Invalid number of arguments".format(sys.argv[0])
        print(s, file=sys.stderr)
        exit(2)

    try:
        actual = parse_version(sys.argv[1]) if len(sys.argv) > 1 else None
        minimum = get_minimum_version()
    except ParseError as e:
        print("{}: {}".format(sys.argv[0], e), file=sys.stderr)
        exit(2)
    else:
        if actual:
            difference = compare_versions(actual, minimum)

            if difference >= 0:
                message = "Python {} interpreter meets {} requirements"
                output=sys.stdout
                status = 0
            else:
                message = "Python {} interpreter does not meet {} requirements"
                output=sys.sterr
                status = 1

            print(message.format(actual, INPUT), file=output)
            exit(status)
        else:
            components = minimum.split('.')
            versions=''

            for n in range(len(components), 0, -1):
                versions += '.'.join(components[:n])

                if n > 1:
                    versions += ' '

            print(versions)
            exit(0)


if __name__ == '__main__':
    main()
