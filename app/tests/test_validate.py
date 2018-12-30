#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from ..uri import _validate_string


class TestValidateFunctions(unittest.TestCase):

    def test_validate_dialect_fail(self):
        self.assertRaises(ValueError,
                          _validate_string,
                          'DATABASE_DIALECT',
                          'mysql!')

    def test_validate_dialect_pass(self):
        value = _validate_string('DATABASE_DIALECT', 'mysql')
        self.assertEqual(value, 'mysql')

    def test_validate_host_fail(self):
        self.assertRaises(ValueError,
                          _validate_string,
                          'DATABASE_HOST',
                          'localhost/')

    def test_validate_host_pass(self):
        value = _validate_string('DATABASE_HOST', 'localhost')
        self.assertEqual(value, 'localhost')

    def test_validate_password_fail(self):
        self.assertRaises(ValueError,
                          _validate_string,
                          'DATABASE_PASSWORD',
                          'Hello!@')

    def test_validate_password_pass(self):
        value = _validate_string('DATABASE_PASSWORD', 'Hello!')
        self.assertEqual(value, 'Hello!')

    def test_validate_schema_fail(self):
        self.assertRaises(ValueError,
                          _validate_string,
                          'DATABASE_SCHEMA',
                          'Hello!@')

    def test_validate_schema_pass(self):
        value = _validate_string('DATABASE_SCHEMA', 'my-database-schema')
        self.assertEqual(value, 'my-database-schema')

    def test_validate_user_fail(self):
        self.assertRaises(ValueError,
                          _validate_string,
                          'DATABASE_USER',
                          'root:')

    def test_validate_user_pass(self):
        value = _validate_string('DATABASE_USER', 'root')
        self.assertEqual(value, 'root')


if __name__ == '__main__':
    unittest.main(verbosity=3)
