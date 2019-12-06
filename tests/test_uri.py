#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from app.uri import _validate


class TestUriMethods(unittest.TestCase):

    def test_validate_charset_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_CHARSET',
                          '.')

    def test_validate_charset_pass_1(self):
        value = _validate('DATABASE_CHARSET', 'utf8')
        self.assertEqual(value, 'utf8')

    def test_validate_charset_pass_2(self):
        value = _validate('DATABASE_CHARSET', 'utf8mb3')
        self.assertEqual(value, 'utf8mb3')

    def test_validate_charset_pass_3(self):
        value = _validate('DATABASE_CHARSET', 'utf8mb4')
        self.assertEqual(value, 'utf8mb4')

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

    def test_validate_dialect_pass_1(self):
        value = _validate('DATABASE_DIALECT', 'mysql')
        self.assertEqual(value, 'mysql')

    def test_validate_dialect_pass_1(self):
        value = _validate('DATABASE_DIALECT', 'sqlite')
        self.assertEqual(value, 'sqlite')

    def test_validate_host_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_HOST',
                          '')

    def test_validate_host_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_HOST',
                          '.')

    def test_validate_host_fail_3(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_HOST',
                          '123abc')

    def test_validate_host_fail_4(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_HOST',
                          'localhost.localdomain')

    def test_validate_host_pass_1(self):
        value = _validate('DATABASE_HOST', '127.0.0.1')
        self.assertEqual(value, '127.0.0.1')

    def test_validate_host_pass_2(self):
        value = _validate('DATABASE_HOST', 'localhost')
        self.assertEqual(value, 'localhost')

    def test_validate_pathname_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '.')

    def test_validate_pathname_fail_2(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '..')

    def test_validate_pathname_fail_3(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          'foo.')

    def test_validate_pathname_fail_4(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PATHNAME',
                          '.foo.')

    def test_validate_pathname_pass_1(self):
        value = _validate('DATABASE_PATHNAME', 'foo')
        self.assertEqual(value, 'foo')

    def test_validate_pathname_pass_2(self):
        value = _validate('DATABASE_PATHNAME', '.foo')
        self.assertEqual(value, '.foo')

    def test_validate_pathname_pass_3(self):
        value = _validate('DATABASE_PATHNAME', 'foo-bar')
        self.assertEqual(value, 'foo-bar')

    def test_validate_pathname_pass_4(self):
        value = _validate('DATABASE_PATHNAME', 'foo-bar.sqlite')
        self.assertEqual(value, 'foo-bar.sqlite')

    def test_validate_pathname_pass_5(self):
        value = _validate('DATABASE_PATHNAME', '/tmp/foo-bar.sqlite')
        self.assertEqual(value, '/tmp/foo-bar.sqlite')

    def test_validate_pathname_pass_6(self):
        value = _validate('DATABASE_PATHNAME', '/home/jdoe/foo-bar.sqlite')
        self.assertEqual(value, '/home/jdoe/foo-bar.sqlite')

    def test_validate_password_pass_1(self):
        value = _validate('DATABASE_PASSWORD', '')
        self.assertEqual(value, '')

    def test_validate_password_pass_2(self):
        password = 'AaBbCc123!@#$%^&*()-=_+[]{}|;:,./<>?'
        value = _validate('DATABASE_PASSWORD', password)
        self.assertEqual(value, password)

    def test_validate_port_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_PORT',
                          '100000')

    def test_validate_port_pass_1(self):
        value = _validate('DATABASE_PORT', '3306')
        self.assertEqual(value, '3306')

    def test_validate_schema_fail_1(self):
        self.assertRaises(ValueError,
                          _validate,
                          'DATABASE_SCHEMA',
                          'my-database-schema/')

    def test_validate_schema_pass_1(self):
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

    def test_validate_user_pass_1(self):
        value = _validate('DATABASE_USER', 'root')
        self.assertEqual(value, 'root')


if __name__ == '__main__':
    unittest.main(verbosity=3)
