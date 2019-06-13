#!/usr/bin/env python3

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

"""Check given Python version string against Pipfile requirement."""

from __future__ import print_function
import argparse
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
PYTHON_VERSION_REGEX = r'^(\d{1,3}(\.\d{1,3}){0,2})(rc\d)?$'

QUOTED_REGEX = r'^"([^"]+)"$'


class ParseError(Exception):
    """Represent error parsing text."""


def get_filepath():
    """Return the fully-qualified path name of the input file."""
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    source_dir = os.path.dirname(script_dir)
    return os.path.join(source_dir, INPUT)


def get_minimum_version():
    """Return the minimum Python version requirement."""
    config = ConfigParser()
    path = get_filepath()
    config.read(path)

    try:
        return parse_version(unquote(config.get(PYTHON_VERSION_PATH[0],
                                                PYTHON_VERSION_PATH[1])))
    except (NoOptionError, NoSectionError, ParseError) as e:
        raise ParseError("{}: Unable to parse: {}".format(path, e))


def parse_args():
    """Parse script arguments."""
    description = 'Check Python interpreter version against Pipfile'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--delimiter',
                        const='_',
                        default='.',
                        metavar='TEXT',
                        nargs='?',
                        help='use TEXT to delimit parts of version in output')
    parser.add_argument('version',
                        metavar='VERSION',
                        nargs='?',
                        help='Check Python version VERSION')
    return parser.parse_args()


def parse_version(s):
    """Parse quoted Python version string."""
    try:
        return re.search(PYTHON_VERSION_REGEX, s).group(1)
    except AttributeError as e:
        raise ParseError("Invalid quoted string '{}': {}".format(s, e))


def print_versions(s, delimiter):
    """Print Python version string with given delimiter."""
    components = s.split('.')
    versions = []

    for n in range(len(components), 0, -1):
        versions.append(delimiter.join(components[:n]))

    print(' '.join(versions))


def unquote(s):
    """Parse a quoted string, stripping quotes."""
    try:
        return re.search(QUOTED_REGEX, s).group(1)
    except AttributeError as e:
        raise ParseError("Invalid quoted string '{}': {}".format(s, e))


def version_str_to_int(s):
    """Return the integer equivalent of a dotted decimal version string."""
    result = 0
    v = s.split('.')

    for i in range(PYTHON_VERSION_LEN):
        result *= 1000
        result += int(v[i]) if i < len(v) else 0

    return result


def main():
    """Main program of script."""
    args = parse_args()

    try:
        actual = parse_version(args.version) if args.version else None
        minimum = get_minimum_version()
    except ParseError as e:
        print("{}: {}".format(sys.argv[0], e), file=sys.stderr)
        exit(2)
    else:
        if actual:
            difference = (version_str_to_int(actual) -
                          version_str_to_int(minimum))

            if difference >= 0:
                message = "Python {} interpreter meets {} requirement"
                output = sys.stdout
                status = 0
            else:
                message = "Python {} interpreter does not meet {} requirement"
                output = sys.stderr
                status = 1

            print(message.format(actual, INPUT), file=output)
            exit(status)
        else:
            print_versions(minimum, args.delimiter)
            exit(0)


if __name__ == '__main__':
    main()
