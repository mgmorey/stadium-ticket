# -*- coding: utf-8 -*-

import re

PATTERN = {
    'DATABASE_HOST': re.compile(r'[\w\d\-\.]+'),
    'DATABASE_PASSWORD': re.compile(r'[\w\d\-\.!\#\$\^&\*\=\+]+'),
    'DATABASE_USER': re.compile(r'[\w\d\-]+'),
    None: re.compile(r'[\w\-]+')
}

def validate_string(parameter: str, value: str) -> str:
    pattern = PATTERN.get(parameter, PATTERN[None])

    if not pattern.fullmatch(value):
        raise ValueError(f"Invalid {parameter} value: \"{value}\"")

    return value
