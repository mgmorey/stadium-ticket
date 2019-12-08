#!/usr/bin/env python3
"""Print application configuration parameters."""

import argparse
import configparser


def format_key(key: str, prefix: str):
    """Return key prefixed with 'APP_' in uppercase"""
    return '_'.join([prefix, key]).upper()


def format_pair(key: str, value: str, prefix: str):
    """Format (key, value) pair for app parameter."""
    return "{0}='{1}'".format(format_key(key, prefix), value)


def get_configuration(args):
    """Return list of app parameters."""
    config = configparser.ConfigParser()
    sections = args.sections.split(',') if args.sections else None
    config.read(args.input)

    if not sections:
        sections = config.sections()

    for section in sections:
        pairs = config[section]

        for key, value in pairs.items():
            print(format_pair(key, value, section))


def parse_args():
    """Parse script arguments."""
    description = 'Print application configuration parameters'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--input',
                        default='app.ini',
                        metavar='INPUT',
                        nargs='?',
                        help='read from file INPUT')
    parser.add_argument('--prefix',
                        default='app',
                        metavar='PREFIX',
                        nargs='?',
                        help='prepend string PREFIX')
    parser.add_argument('--sections',
                        metavar='SECTIONS',
                        nargs='?',
                        help='read sections SECTIONS')
    return parser.parse_args()


def main():
    """Main program of script."""
    args = parse_args()
    get_configuration(args)


if __name__ == '__main__':
    main()
