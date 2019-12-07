#!/usr/bin/env python3

import configparser

def format_parameter(key, value):
    return f"{get_app_parameter(key)}='{value}'"


def get_app_parameter(key):
    return '_'.join(['app', key]).upper()


def get_parameters():
    config = configparser.ConfigParser()
    config.read('app.ini')
    names = config['names']

    for key, value in names.items():
        print(format_parameter(key, value))


if __name__ == '__main__':
    get_parameters()
