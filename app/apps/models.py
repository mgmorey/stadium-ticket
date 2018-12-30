# -*- coding: utf-8 -*-
"""Define data models for apps."""

from app.app import db


class Events(db.Model):
    # pylint: disable=too-few-public-methods
    """Represent one or more stadium events to which tickets are sold."""
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)

    def __repr__(self):
        return '<Events %r>' % self.name
