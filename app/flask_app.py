#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manage ticket sales for stadium events via a RESTful API."""

import logging

from flask import abort, jsonify, request

from .app import create_app, db
from .apps import Events
from .tickets import SoldOut, Tickets
from .uri import get_uri

LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"
SQLALCHEMY_DATABASE_URI = get_uri()
SQLALCHEMY_TRACK_MODIFICATIONS = False

app = create_app(__name__)  # pylint: disable=invalid-name


@app.route('/stadium/event', methods=['PUT'])
def add_event():
    """Add an event to the calendar."""

    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'event', 'total'}:
        abort(400)

    if request.json['command'] != 'add_event':
        abort(400)

    event_name = request.json['event']
    event_total = request.json['total']
    event = Events(name=event_name, sold=0, total=event_total)
    db.session.add(event)
    try:
        db.session.commit()
    except sqlalchemy.exc.IntegrityError as error:
        logging.error("Error adding event: %s", str(error))
        abort(400, 'Duplicate event')
    else:
        return jsonify({'event_name': event_name})


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
        logging.error("Error requesting ticket: %s", str(error))
        abort(400, 'No tickets available')
    else:
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
        logging.error("Error requesting tickets: %s", str(error))
        abort(400, 'No tickets available')
    return jsonify({'ticket_number': tickets.serial,
                    'ticket_count': tickets.count,
                    'time': tickets.issue})
