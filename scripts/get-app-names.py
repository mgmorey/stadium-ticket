#!/usr/bin/env python3
"""Print list of (key, value) pairs for app parameters."""

import configparser


def format_parameter(key: str, value: str):
    """Format (key, value) pair for app parameter."""
    return "{0}='{1}'".format(get_app_parameter(key), value)


def get_app_parameter(key: str):
    """Return key prefixed with 'APP_' in uppercase"""
    return '_'.join(['app', key]).upper()


def get_parameters():
    """Return list of app parameters."""
    config = configparser.ConfigParser()
    config.read('app.ini')
    names = config['names']

    for key, value in names.items():
        print(format_parameter(key, value))


if __name__ == '__main__':
    get_parameters()
