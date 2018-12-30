#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manage ticket sales for a stadium event via a RESTful API."""

import datetime
import logging

from flask import Flask, abort, jsonify, request
from flask_script import Manager
from flask_sqlalchemy import SQLAlchemy

from .uri import get_uri

LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"
SQLALCHEMY_DATABASE_URI = get_uri()
SQLALCHEMY_TRACK_MODIFICATIONS = False

# pylint: disable=invalid-name
app = Flask(__name__)
app.config.from_object(__name__)
db = SQLAlchemy(app)
manager = Manager(app)
# pylint: enable=invalid-name


class Events(db.Model):
    # pylint: disable=too-few-public-methods
    """Represent one or more stadium events for which tickets are sold."""
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)

    def __repr__(self):
        return '<Events %r>' % self.name


class SoldOut(Exception):
    """Represent tickets sold out error."""


class Tickets():
    """Represent a series of one or more tickets for a stadium event."""
    MAX_NUMBER = None

    @staticmethod
    def generate_serial(session, event_name: str, count: int = 1):
        """Return a ticket number and count for a series of tickets."""
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        last_serial = event.sold

        if Tickets.MAX_NUMBER is not None:
            if last_serial + count > Tickets.MAX_NUMBER:
                raise SoldOut("maximum serial number: {Tickets.MAX_NUMBER}")

        sold = event.sold
        event.sold = sold + count
        session.commit()
        return sold, count

    @staticmethod
    def last_serial(session, event_name: str) -> int:
        """Return the number of the last ticket sold."""
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        return event.sold

    def __init__(self, session, event: str, count: int = 1):
        """Initialize a series of tickets for a given event and count."""
        last_serial, count = Tickets.generate_serial(session, event, count)
        self._count = count
        self._event = event
        self._issue = datetime.datetime.utcnow()
        self._serial = last_serial

    @property
    def count(self) -> int:
        """Return the number of tickets in the series."""
        return self._count

    @property
    def event(self) -> str:
        """Return the name of the event for the tickets."""
        return self._event

    @property
    def issue(self) -> str:
        """Return the ticket issue timestamp in ISO format."""
        return self._issue.isoformat()

    @property
    def serial(self) -> int:
        """Return the number of the first ticket in the series."""
        return self._serial


@app.route('/stadium/ticket', methods=['PUT'])
def request_ticket():
    """Request a single ticket for an event."""
    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'event'}:
        abort(400)

    if request.json['command'] != 'request_ticket':
        abort(400)

    try:
        ticket = Tickets(db.session, request.json['event'])
    except SoldOut as error:
        logging.exception("Error requesting ticket: %s", str(error))
        abort(500)
    return jsonify({'ticket_number': ticket.serial,
                    'time': ticket.issue})


@app.route('/stadium/tickets', methods=['PUT'])
def request_tickets():
    """Request one or more tickets for an event."""
    max_count = 10
    min_count = 1

    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'count', 'event'}:
        abort(400)

    if request.json['command'] != 'request_ticket':
        abort(400)

    count = request.json['count']

    if isinstance(count, str):
        if count.isdigit():
            count = int(count)
        else:
            abort(400)

    count = max(count, min_count)
    count = min(count, max_count)

    try:
        tickets = Tickets(db.session, request.json['event'], count)
    except SoldOut as error:
        logging.exception("Error requesting tickets: %s", str(error))
        abort(500)
    return jsonify({'ticket_number': tickets.serial,
                    'ticket_count': tickets.count,
                    'time': tickets.issue})


if __name__ == '__main__':
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    manager.run()
