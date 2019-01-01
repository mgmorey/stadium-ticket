#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from app.apps import Events
from app.flask_app import app, db, SoldOut, Tickets

EVENT_1 = 'The Beatles'
EVENT_2 = 'The Cure'
EVENT_3 = 'The Doors'
EVENT_4 = 'The Who'
EVENT_5 = 'SoldOut'
EVENTS = [EVENT_1, EVENT_2, EVENT_3, EVENT_4, EVENT_5]


class TestTicketsMethods(unittest.TestCase):
    events = {}

    @classmethod
    def setUpClass(cls):
        with app.app_context():
            try:
                for event_name in EVENTS:
                    db.session.add(Events(name=event_name, sold=0, total=1000))
                    db.session.commit()
            except:
                db.session.rollback()

    def add_serial(self, event: str, serial: int, count: int = 1):
        if event not in self.events:
            self.events[event] = set()

        for i in range(serial, serial + count):
            self.assertNotIn(i, self.events[event])
            self.events[event].add(i)

    def sell_tickets(self, event: str, count: int = 1):
        Tickets.LIMIT_SALES = False
        with app.app_context():
            last = Tickets.get_last_serial(db.session, event)
            t = Tickets(db.session, event, count)
            self.assertEqual(t.event, event)
            self.assertEqual(t.serial, last)
            self.add_serial(event, t.serial, count)

    def sell_out_tickets(self, event: str, count: int = 1):
        Tickets.LIMIT_SALES = True
        with app.app_context():
            with self.assertRaises(SoldOut):
                t = Tickets(db.session, event, count)

    def test_sell_event_1_ticket(self):
        self.sell_tickets(EVENT_1)

    def test_sell_event_2_tickets_10(self):
        self.sell_tickets(EVENT_2, 10)

    def test_sell_event_3_tickets_100(self):
        self.sell_tickets(EVENT_3, 100)

    def test_sell_event_4_tickets_1001(self):
        self.sell_tickets(EVENT_4, 1000)

    def test_sell_out_event_5_tickets_1001(self):
        self.sell_out_tickets(EVENT_5, 1001)


if __name__ == '__main__':
    unittest.main(verbosity=3)
