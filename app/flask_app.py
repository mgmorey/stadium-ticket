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


@app.route('/stadium/event', methods=['GET', 'DELETE', 'PUT'])
def event():
    """Add, retrieve or replace an event."""

    if request.method == 'GET':
        event_name = request.args.get('name')

        if not event_name:
            abort(400)

        query = db.session.query(Events)
        query = query.filter(Events.name == event_name)
        event = query.first()

        if not event:
            abort(404)

        return jsonify({'event': event.name})
    elif request.method == 'DELETE':
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
    elif request.method == 'PUT':
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


@app.route('/stadium/events', methods=['GET'])
def events():
    """Retrieve a list of all events."""

    events = [e.name for e in db.session.query(Events).all()]
    return jsonify({'events': events})


@app.route('/stadium/tickets', methods=['POST'])
def tickets():
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
