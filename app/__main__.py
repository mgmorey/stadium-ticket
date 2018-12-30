#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Script to invoke the stadium tickets RESTful API."""

import logging

from flask_script import Manager

from .flask_app import LOGGING_FORMAT, app, db

manager = Manager(app)  # pylint: disable=invalid-name


@manager.command
def init_db():
    """Create database schema and tables."""
    with app.app_context():
        db.create_all()


def main():
    """Main method (called when module invoked as a script)."""
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    manager.run()


if __name__ == '__main__':
    main()
