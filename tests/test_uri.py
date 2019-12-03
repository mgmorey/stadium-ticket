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
                          'DATABASE_PATHNAME',
                          '.')

    def test_validate_filename_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '..')

    def test_validate_filename_fail_3(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '.foo')

    def test_validate_filename_fail_4(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          'foo.')

    def test_validate_filename_fail_5(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '.foo.sqlite')

    def test_validate_filename_pass_1(self):
        value = _validate('DATABASE_PATHNAME', 'foo')
        self.assertEqual(value, 'foo')

    def test_validate_filename_pass_2(self):
        value = _validate('DATABASE_PATHNAME', 'stadium-tickets')
        self.assertEqual(value, 'stadium-tickets')

    def test_validate_filename_pass_3(self):
        value = _validate('DATABASE_PATHNAME', '/tmp/foo.sqlite')
        self.assertEqual(value, '/tmp/foo.sqlite')

    def test_validate_filename_pass_4(self):
        value = _validate('DATABASE_PATHNAME', '/home/jsmith/foo.sqlite')
        self.assertEqual(value, '/home/jsmith/foo.sqlite')

    def test_validate_filename_pass_5(self):
        value = _validate('DATABASE_PATHNAME', 'stadium-tickets.sqlite')
        self.assertEqual(value, 'stadium-tickets.sqlite')

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
