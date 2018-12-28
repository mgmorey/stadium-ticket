#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manage ticket sales for a stadium event via a RESTful API."""

import logging

from flask import Flask, abort, jsonify, request
from flask_script import Manager

from .database import db, get_uri, session
from .tickets import SoldOut, Tickets

LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"

SQLALCHEMY_DATABASE_URI = get_uri()
SQLALCHEMY_TRACK_MODIFICATIONS = False

app = Flask(__name__)
app.config.from_object(__name__)
db.init_app(app)
manager = Manager(app)


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
        ticket = Tickets(session, request.json['event'])
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
        tickets = Tickets(session, request.json['event'], count)
    except SoldOut as error:
        logging.exception("Error requesting tickets: %s", str(error))
        abort(500)
    return jsonify({'ticket_number': tickets.serial,
                    'ticket_count': tickets.count,
                    'time': tickets.issue})


if __name__ == '__main__':
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    manager.run()
