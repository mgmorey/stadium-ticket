#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from app.uri import _validate


class TestUriMethods(unittest.TestCase):

    def test_validate_charset_fail_1(self):
        self.assertRaises(ValueError, _validate, 'charset', '.')

    def test_validate_charset_pass_1(self):
        value = _validate('charset', 'utf8')
        self.assertEqual(value, 'utf8')

    def test_validate_charset_pass_2(self):
        value = _validate('charset', 'utf8mb3')
        self.assertEqual(value, 'utf8mb3')

    def test_validate_charset_pass_3(self):
        value = _validate('charset', 'utf8mb4')
        self.assertEqual(value, 'utf8mb4')

    def test_validate_dialect_fail_1(self):
        self.assertRaises(ValueError, _validate, 'dialect', '.')

    def test_validate_dialect_fail_2(self):
        self.assertRaises(ValueError, _validate, 'dialect', '$mysql')

    def test_validate_dialect_fail_3(self):
        self.assertRaises(ValueError, _validate, 'dialect', 'mysql+')

    def test_validate_dialect_pass_1(self):
        value = _validate('dialect', 'mysql')
        self.assertEqual(value, 'mysql')

    def test_validate_dialect_pass_1(self):
        value = _validate('dialect', 'sqlite')
        self.assertEqual(value, 'sqlite')

    def test_validate_host_fail_1(self):
        self.assertRaises(ValueError, _validate, 'host', '')

    def test_validate_host_fail_2(self):
        self.assertRaises(ValueError, _validate, 'host', '.')

    def test_validate_host_fail_3(self):
        self.assertRaises(ValueError, _validate, 'host', '123abc')

    def test_validate_host_pass_1(self):
        value = _validate('host', '127.0.0.1')
        self.assertEqual(value, '127.0.0.1')

    def test_validate_host_pass_2(self):
        value = _validate('host', 'localhost')
        self.assertEqual(value, 'localhost')

    def test_validate_host_fail_4(self):
        value = _validate('host', 'localhost.localdomain')
        self.assertEqual(value, 'localhost.localdomain')

    def test_validate_pathname_fail_1(self):
        self.assertRaises(ValueError, _validate, 'pathname', '.')

    def test_validate_pathname_fail_2(self):
        self.assertRaises(ValueError, _validate, 'pathname', '..')

    def test_validate_pathname_fail_3(self):
        self.assertRaises(ValueError, _validate, 'pathname', 'foo.')

    def test_validate_pathname_fail_4(self):
        self.assertRaises(ValueError, _validate, 'pathname', '.foo.')

    def test_validate_pathname_pass_1(self):
        value = _validate('pathname', 'foo')
        self.assertEqual(value, 'foo')

    def test_validate_pathname_pass_2(self):
        value = _validate('pathname', '.foo')
        self.assertEqual(value, '.foo')

    def test_validate_pathname_pass_3(self):
        value = _validate('pathname', 'foo-bar')
        self.assertEqual(value, 'foo-bar')

    def test_validate_pathname_pass_4(self):
        value = _validate('pathname', 'foo-bar.sqlite')
        self.assertEqual(value, 'foo-bar.sqlite')

    def test_validate_pathname_pass_5(self):
        value = _validate('pathname', '/tmp/foo-bar.sqlite')
        self.assertEqual(value, '/tmp/foo-bar.sqlite')

    def test_validate_pathname_pass_6(self):
        value = _validate('pathname', '/home/jdoe/foo-bar.sqlite')
        self.assertEqual(value, '/home/jdoe/foo-bar.sqlite')

    def test_validate_password_pass_1(self):
        value = _validate('password', '')
        self.assertEqual(value, '')

    def test_validate_password_pass_2(self):
        password = 'AaBbCc123!@#$%^&*()-=_+[]{}|;:,./<>?'
        value = _validate('password', password)
        self.assertEqual(value, password)

    def test_validate_port_fail_1(self):
        self.assertRaises(ValueError, _validate, 'port', '100000')

    def test_validate_port_pass_1(self):
        value = _validate('port', '3306')
        self.assertEqual(value, '3306')

    def test_validate_schema_fail_1(self):
        self.assertRaises(ValueError, _validate, 'schema',
                          'my-database-schema/')

    def test_validate_schema_pass_1(self):
        value = _validate('schema', 'my-database-schema')
        self.assertEqual(value, 'my-database-schema')

    def test_validate_user_fail_1(self):
        self.assertRaises(ValueError, _validate, 'user', '.')

    def test_validate_user_fail_2(self):
        self.assertRaises(ValueError, _validate, 'user', 'root:')

    def test_validate_user_fail_3(self):
        self.assertRaises(ValueError, _validate, 'user', 'root@')

    def test_validate_user_pass_1(self):
        value = _validate('user', 'root')
        self.assertEqual(value, 'root')


if __name__ == '__main__':
    unittest.main(verbosity=3)
