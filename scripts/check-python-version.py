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

import configparser
import os
import re
import sys

PIPFILE = 'Pipfile'
QUOTED_RE = r'^"([^"]+)"$'
VERSION_RE = r'^(\d{1,3}(\.\d{1,3}){0,2})$'


class VersionParseError(Exception):
    pass


def compare_versions(s1, s2):
    return compute_scalar_version(s1) - compute_scalar_version(s2)


def compute_scalar_version(s):
    result = 0
    v = s.split('.')

    for i in range(3):
        result *= 1000
        result += int(v[i]) if i < len(v) else 0

    return result


def get_minimum_version():
    config = configparser.ConfigParser()
    path = get_pipfile_path()

    try:
        config.read(path)
        version = None

        if 'requires' in config:
            requires = config['requires']

            if 'python_version' in requires:
                return parse_version(unquote(requires['python_version']))

        raise VersionParseError("No python version found")
    except (KeyError, VersionParseError) as e:
        s = "{}: Unable to parse file: {}".format(path, e)
        raise VersionParseError(s)


def get_pipfile_path():
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    source_dir = os.path.dirname(script_dir)
    return os.path.join(source_dir, PIPFILE)


def parse_version(s):
    try:
        return re.search(VERSION_RE, s).group(1)
    except AttributeError as e:
        raise VersionParseError("Invalid version string '{}'".format(s))


def unquote(s):
    try:
        return re.search(QUOTED_RE, s).group(1)
    except AttributeError as e:
        raise VersionParseError("Invalid quoted string '{}'".format(s))


def main():
    if len(sys.argv) != 2:
        s = "{}: Invalid number of arguments".format(sys.argv[0])
        print(s, file=sys.stderr)
        exit(2)

    try:
        actual = parse_version(sys.argv[1])
        minimum = get_minimum_version()
    except VersionParseError as e:
        s = "{}: {}".format(sys.argv[0], e)
        print(s, file=sys.stderr)
        exit(2)
    else:
        difference = compare_versions(actual, minimum)

        if difference >= 0:
            s = 'meets'
            status = 0
        else:
            s = 'does not meet'
            status = 1

        print("Python {} {} the minimum "
              "version requirement ({})".format(actual, s, minimum))
        exit(status)


if __name__ == '__main__':
    main()
