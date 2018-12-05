#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from app.database.validate import validate_string


class TestValidateFunctions(unittest.TestCase):

    def test_validate_dialect(self):
        validate_string('DATABASE_DIALECT', 'mysql')

    def test_validate_host(self):
        validate_string('DATABASE_HOST', 'localhost')

    def test_validate_password(self):
        validate_string('DATABASE_PASSWORD', 'Hello!')

    def test_validate_user(self):
        validate_string('DATABASE_DIALECT', 'root')


if __name__ == '__main__':
    unittest.main(verbosity=3)
