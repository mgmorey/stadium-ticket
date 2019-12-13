#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests

HOST = 'localhost'
PORT = '5000'

BASE_URL = f"http://{HOST}:{PORT}"
URL_EVENT = f"{BASE_URL}/stadium/event"
URL_EVENTS = f"{BASE_URL}/stadium/events"
URL_TICKETS = f"{BASE_URL}/stadium/tickets"

EVENT_1 = 'The Beatles'
EVENT_2 = 'The Cure'
EVENT_3 = 'The Doors'
EVENT_4 = 'The Who'
EVENT_5 = 'Alizée'
EVENT_6 = 'Maître Gims'
EVENT_7 = 'SoldOut'
EVENTS = {EVENT_1, EVENT_2, EVENT_3, EVENT_4, EVENT_5, EVENT_6, EVENT_7}


def delete_event(name: str):
    return requests.delete(f"{URL_EVENT}?name={name}")


def get_event(name: str):
    return requests.get(f"{URL_EVENT}?name={name}")


def get_events():
    return requests.get(URL_EVENTS)


def post_ticket(name: str, count: int):
    return requests.post(URL_TICKETS, json={
        'command': 'request_tickets',
        'event': name,
        'count': count,
    })


def put_event(name: str, total: int):
    return requests.put(URL_EVENT, json={
        'command': 'add_event',
        'event': name,
        'total': total,
    })


def test_01_events_put():
    for name in EVENTS:
        response = put_event(name, 1000)
        assert response.status_code == 200


def test_02_events_get():
    response = get_events()
    assert response.status_code == 200
    events = response.json().get('events')
    assert set(events) == EVENTS


def test_03_event_get():
    for name in EVENTS:
        response = get_event(name)
        assert response.status_code == 200
        event = response.json().get('event')
        assert event == {
            'name': name,
            'sold': 0,
            'total': 1000,
        }


def test_05_ticket_post():
    for name in EVENTS:
        response = post_ticket(name, 1)
        assert response.status_code == 200


def test_04_event_delete():
    for name in EVENTS:
        response = delete_event(name)
        assert response.status_code == 200

    response = get_events()
    assert response.status_code == 200
    events = response.json().get('events')
    assert events == []
