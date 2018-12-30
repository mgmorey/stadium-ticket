# -*- coding: utf-8 -*-
"""Define db object and app creation factory method."""

from flask import Flask, abort, jsonify, request
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()  # pylint: disable=invalid-name


def create_app(config_name):
    """Return an app object."""
    app = Flask(__name__)
    app.config.from_object(config_name)
    db.init_app(app)
    return app
