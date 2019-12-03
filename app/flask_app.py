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

APP_NAME = 'stadium-ticket'
APP_SCHEMA = 'stadium-tickets'
APP_VARDIR = '/var/opt/{}'.format(APP_NAME)
LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"
SQLALCHEMY_DATABASE_URI = get_uri(APP_SCHEMA, APP_VARDIR)
SQLALCHEMY_TRACK_MODIFICATIONS = False

app = create_app(__name__)  # pylint: disable=invalid-name


@app.route('/stadium/event', methods=['DELETE'])
def stadium_event_delete():
    """Remove an event."""
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
        abort(500, 'Integrity error')
    else:
        return jsonify({})


@app.route('/stadium/event', methods=['GET'])
def stadium_event_get():
    """Retrieve an event."""
    event_name = request.args.get('name')

    if not event_name:
        abort(400)

    query = db.session.query(Events)
    query = query.filter(Events.name == event_name)
    event = query.first()

    if not event:
        abort(404)

    result = {
        'event': {
            'name': event.name,
            'sold': event.sold,
            'total': event.total
        }
    }
    return jsonify(result)


@app.route('/stadium/event', methods=['PUT'])
def stadium_event_put():
    """Add, replace an event."""
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
        abort(500, 'Integrity error')
    else:
        return jsonify({'event_name': event_name})


@app.route('/stadium/events', methods=['GET'])
def stadium_events_get():
    """Retrieve a list of all events."""

    events = [e.name for e in db.session.query(Events).all()]
    return jsonify({'events': events})


@app.route('/stadium/tickets', methods=['POST'])
def stadium_tickets_post():
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
