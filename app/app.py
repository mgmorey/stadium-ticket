#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging

from flask import Flask, abort, jsonify, request

from database import get_session, get_uri
from tickets import Tickets

LOGGING_FORMAT = "%(asctime)s %(levelname)s %(message)s"
MAX_COUNT = 10
MIN_COUNT = 1

app = Flask(__name__)
session = get_session()
Tickets.MAX_NUMBER = None


@app.route('/stadium/ticket', methods=['PUT'])
def request_ticket():
    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'event'}:
        abort(400)

    if request.json['command'] != 'request_ticket':
        abort(400)

    try:
        t = Tickets(session, request.json['event'])
    except Exception as e:
        logging.exception("Error requesting ticket: %s", str(e))
        abort(500)
    return jsonify({'ticket_number': t.serial,
                    'time': t.issue})


@app.route('/stadium/tickets', methods=['PUT'])
def request_tickets():
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

    count = max(count, MIN_COUNT)
    count = min(count, MAX_COUNT)

    try:
        t = Tickets(session, request.json['event'], count)
    except Exception as e:
        logging.exception("Error requesting tickets: %s", str(e))
        abort(500)
    return jsonify({'ticket_number': t.serial,
                    'ticket_count': t.count,
                    'time': t.issue})


if __name__ == '__main__':
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    uri = get_uri()
    logging.getLogger(__name__).info("Connecting to %s", uri)
    app.run()
