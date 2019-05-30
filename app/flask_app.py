#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manage ticket sales for stadium events via a RESTful API."""

import logging

from flask import abort, jsonify, request
from sqlalchemy.exc import IntegrityError

from .app import create_app, db
from .apps import Events
from .tickets import SoldOut, Tickets
from .uri import get_uri

LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"
SQLALCHEMY_DATABASE_URI = get_uri()
SQLALCHEMY_TRACK_MODIFICATIONS = False

app = create_app(__name__)  # pylint: disable=invalid-name


@app.route('/stadium/event', methods=['PUT'])
def add_or_replace_event():
    """Add (or replace) an event to (or on) the calendar."""

    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'event', 'total'}:
        abort(400)

    if request.json['command'] not in {'add_event', 'replace_event'}:
        abort(400)

    event_name = request.json['event']
    event_total = request.json['total']
    query = db.session.query(Events)
    query = query.filter(Events.name == event_name)
    query.delete()
    event = Events(name=event_name, sold=0, total=event_total)
    db.session.add(event)
    try:
        db.session.commit()
    except IntegrityError as error:
        logging.error("Error adding event: %s", str(error))
        abort(400, 'Duplicate event')
    else:
        return jsonify({'event_name': event_name})


@app.route('/stadium/event', methods=['GET'])
def get_event():
    """Retrieve an event from the calendar."""

    event_name = request.args.get('name')

    if not event_name:
        abort(400)

    query = db.session.query(Events)
    query = query.filter(Events.name == event_name)
    return jsonify({'event': query})


@app.route('/stadium/events', methods=['GET'])
def get_events():
    """Retrieve a list of events from the calendar."""

    events = [e.name for e in db.session.query(Events).all()]
    return jsonify({'events': events})


@app.route('/stadium/event', methods=['DELETE'])
def remove_event():
    """Remove an event from the calendar."""

    event_name = request.args.get('name')

    if not event_name:
        abort(400)

    query = db.session.query(Events)
    query = query.filter(Events.name == event_name)
    query.delete()
    try:
        db.session.commit()
    except IntegrityError as error:
        logging.error("Error removing event: %s", str(error))
        abort(400, 'No such event')
    else:
        return jsonify({'event_name': event_name})


@app.route('/stadium/tickets', methods=['POST'])
def request_tickets():
    """Request one or more tickets for an event."""
    max_count = 10
    min_count = 1

    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'count', 'event'}:
        abort(400)

    if request.json['command'] != 'request_tickets':
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
