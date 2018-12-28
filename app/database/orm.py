# -*- coding: utf-8 -*-
"""Import Flask-SQLAlchemy modules and define Events class."""

from flask_sqlalchemy import SQLAlchemy

# pylint: disable=invalid-name
db = SQLAlchemy()
# pylint: enable=invalid-name


class Events(db.Model):
    # pylint: disable=no-member,too-few-public-methods
    """Represent one or more stadium events for which tickets are sold."""
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)
