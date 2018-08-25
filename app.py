#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask
from flask import abort
from flask import jsonify
from flask import request

import tickets

MAX_COUNT = 10
MIN_COUNT = 1

app = Flask(__name__)

tickets.MAX_NUMBER = None


@app.route('/stadium/ticket', methods=['PUT'])
def request_ticket():
    if not request.json:
        abort(400)

    if set(request.json.keys()) != {'command', 'event'}:
        abort(400)

    if request.json['command'] != 'request_ticket':
        abort(400)

    try:
        t = tickets.Tickets(request.json['event'])
    except Exception as e:
        abort(400)
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
        t = tickets.Tickets(request.json['event'], count)
    except Exception as e:
        abort(400)
    return jsonify({'ticket_number': t.serial,
                    'ticket_count': t.count,
                    'time': t.issue})


if __name__ == '__main__':
    app.run(debug=True)
