# -*- coding: utf-8 -*-
"""Import Flask-SQLAlchemy modules and define Events class."""

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
session = db.session


class Events(db.Model):
    """Represent one or more stadium events for which tickets are sold."""
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)
