#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Define SoldOut and Tickets classes for stadium events."""

import datetime

from .apps import Events


class SoldOut(Exception):
    """Represent tickets sold out error."""


class Tickets():
    """Represent one or more tickets for a stadium event."""
    MAX_NUMBER = None

    @staticmethod
    def generate_serial(session, event_name: str, count: int = 1):
        """Return a ticket number and count for a series of tickets."""
        event = Tickets.get_event(session, event_name)

        if Tickets.MAX_NUMBER is not None:
            if event.sold + count > event.total:
                raise SoldOut("maximum serial number: {event.total}")

        sold = event.sold
        event.sold = sold + count
        session.commit()
        return sold, count

    @staticmethod
    def get_event(session, event_name: str):
        """Return an event object for a given event name."""
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        return event

    @staticmethod
    def get_last_serial(session, event_name: str) -> int:
        """Return the next serial number available for a given event name."""
        event = Tickets.get_event(session, event_name)
        return event.sold

    def __init__(self, session, event: str, count: int = 1):
        """Initialize a series of tickets for a given event and count."""
        last_serial, count = Tickets.generate_serial(session, event, count)
        self._count = count
        self._event = event
        self._issue = datetime.datetime.utcnow()
        self._serial = last_serial

    @property
    def count(self) -> int:
        """Return the number of tickets in the series."""
        return self._count

    @property
    def event(self) -> str:
        """Return the name of the event for the tickets."""
        return self._event

    @property
    def issue(self) -> str:
        """Return the ticket issue timestamp in ISO format."""
        return self._issue.isoformat()

    @property
    def serial(self) -> int:
        """Return the number of the first ticket in the series."""
        return self._serial
