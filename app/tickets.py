# -*- coding: utf-8 -*-
"""Define classes to solve stadium ticket vending problem."""

import datetime

from .database import Events, db


class SoldOut(Exception):
    """Represent tickets sold out error."""


class Tickets():
    """Represent a series of one or more tickets for a stadium event."""
    MAX_NUMBER = None

    @staticmethod
    def generate_serial(session, event_name: str, count: int = 1):
        """Return a ticket number and count for a series of tickets."""
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        last_serial = event.sold

        if Tickets.MAX_NUMBER is not None:
            if last_serial + count > Tickets.MAX_NUMBER:
                raise SoldOut("maximum serial number: {Tickets.MAX_NUMBER}")

        sold = event.sold
        event.sold = sold + count
        session.commit()
        return sold, count

    @staticmethod
    def last_serial(session, event_name: str) -> int:
        """Return the number of the last ticket sold."""
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
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
