#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests

from app.apps import Events
from app.flask_app import app, db

HOST = 'localhost'
PORT = '5000'

BASE_URL = f"http://{HOST}:{PORT}"
URL_EVENTS = f"{BASE_URL}/stadium/events"

EVENT_1 = 'The Beatles'
EVENT_2 = 'The Cure'
EVENT_3 = 'The Doors'
EVENT_4 = 'The Who'
EVENT_5 = 'Alizée'
EVENT_6 = 'Maître Gims'
EVENT_7 = 'SoldOut'
EVENTS = {EVENT_1, EVENT_2, EVENT_3, EVENT_4, EVENT_5, EVENT_6, EVENT_7}


def set_up():
    with app.app_context():
        db.create_all()
        events = {Events(name=name, sold=0, total=1000) for name in EVENTS}

        for event in events:
            db.session.add(event)
            try:
                db.session.commit()
            except Exception as error:
                db.session.rollback()


def test_api():
    set_up()
    response = requests.get(URL_EVENTS)
    assert response.status_code == 200
    json_response = response.json()
    events = json_response.get('events')
    assert set(events) == EVENTS
