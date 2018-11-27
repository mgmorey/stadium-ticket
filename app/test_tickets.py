#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest

from database import get_session
from tickets import Tickets

EVENT_1 = 'The Beatles'
EVENT_2 = 'The Cure'
EVENT_3 = 'The Doors'
EVENT_4 = 'The Who'
EVENT_5 = 'SoldOut'


class TestTicketsMethods(unittest.TestCase):
    events = {}

    def add_serial(self, event: str, serial: int, count: int = 1):
        if event not in self.events:
            self.events[event] = set()

        for i in range(serial, serial + count):
            self.assertNotIn(i, self.events[event])
            self.events[event].add(i)

    def sell_tickets(self, event: str, count: int = 1):
        session = get_session()
        last_serial = Tickets.last_serial(session, event)
        t = Tickets(session, event, count)
        self.assertEqual(t.event, event)
        self.assertEqual(t.serial, last_serial)
        self.add_serial(event, t.serial, count)

    def sell_out_tickets(self, event: str, count: int = 1):
        Tickets.MAX_NUMBER = 0
        session = get_session()
        with self.assertRaises(Tickets.SoldOut):
            t = Tickets(session, event, count)

    def test_sell_event_1_ticket(self):
        self.sell_tickets(EVENT_1)

    def test_sell_event_2_tickets_10(self):
        self.sell_tickets(EVENT_2, 10)

    def test_sell_event_3_tickets_100(self):
        self.sell_tickets(EVENT_3, 100)

    def test_sell_event_4_tickets_1001(self):
        self.sell_tickets(EVENT_4, 1000)

    def test_sell_out_event_5_tickets_1001(self):
        self.sell_out_tickets(EVENT_5)


if __name__ == '__main__':
    unittest.main(verbosity=3)
