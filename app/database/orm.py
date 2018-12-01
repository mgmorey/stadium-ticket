# -*- coding: utf-8 -*-

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
session = db.session


class Events(db.Model):
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)
