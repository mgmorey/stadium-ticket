#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from app.uri import _validate


class TestUriMethods(unittest.TestCase):

    def test_validate_dialect_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_DIALECT',
                          '.')

    def test_validate_dialect_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_DIALECT',
                          '$mysql')

    def test_validate_dialect_fail_3(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_DIALECT',
                          'mysql+')

    def test_validate_dialect_pass(self):
        value = _validate('DATABASE_DIALECT', 'mysql')
        self.assertEqual(value, 'mysql')

    def test_validate_filename_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_FILENAME',
                          '.')

    def test_validate_filename_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_FILENAME',
                          '.foo.sqlite')

    def test_validate_filename_pass(self):
        value = _validate('DATABASE_FILENAME', 'foo.sqlite')
        self.assertEqual(value, 'foo.sqlite')

    def test_validate_host_fail(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_HOST',
                          'localhost/')

    def test_validate_host_pass(self):
        value = _validate('DATABASE_HOST', 'localhost')
        self.assertEqual(value, 'localhost')

    def test_validate_password_fail(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PASSWORD',
                          'Hello!@')

    def test_validate_password_pass(self):
        value = _validate('DATABASE_PASSWORD', 'Hello!')
        self.assertEqual(value, 'Hello!')

    def test_validate_schema_fail(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_SCHEMA',
                          'my-database-schema/')

    def test_validate_schema_pass(self):
        value = _validate('DATABASE_SCHEMA', 'my-database-schema')
        self.assertEqual(value, 'my-database-schema')

    def test_validate_user_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_USER',
                          '.')

    def test_validate_user_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_USER',
                          'root:')

    def test_validate_user_fail_3(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_USER',
                          'root@')

    def test_validate_user_pass(self):
        value = _validate('DATABASE_USER', 'root')
        self.assertEqual(value, 'root')


if __name__ == '__main__':
    unittest.main(verbosity=3)
