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


logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
manager.run()
