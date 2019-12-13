#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests

HOST = 'localhost'
PORT = '5000'

BASE_URL = f"http://{HOST}:{PORT}"
URL_EVENT = f"{BASE_URL}/stadium/event"
URL_EVENTS = f"{BASE_URL}/stadium/events"

EVENT_1 = 'The Beatles'
EVENT_2 = 'The Cure'
EVENT_3 = 'The Doors'
EVENT_4 = 'The Who'
EVENT_5 = 'Alizée'
EVENT_6 = 'Maître Gims'
EVENT_7 = 'SoldOut'
EVENTS = {EVENT_1, EVENT_2, EVENT_3, EVENT_4, EVENT_5, EVENT_6, EVENT_7}


def add_event(event, total):
    return requests.put(URL_EVENT, json={
        'command': 'add_event',
        'event': event,
        'total': total
    })


def get_events():
    return requests.get(URL_EVENTS)


def test_events_add():
    events = {name for name in EVENTS}

    for event in events:
        response = add_event(event, 1000)
        assert response.status_code == 200


def test_event_get():
    response = get_events()
    assert response.status_code == 200
    events = response.json().get('events')
    assert set(events) == EVENTS
