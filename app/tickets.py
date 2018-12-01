# -*- coding: utf-8 -*-

import datetime

from database import Events, session


class SoldOut(Exception):
    pass


class Tickets(object):
    MAX_NUMBER = None

    @staticmethod
    def generate_serial(session, event_name: str, count: int = 1):
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        last_serial = event.sold

        if Tickets.MAX_NUMBER is not None:
            if last_serial + count > Tickets.MAX_NUMBER:
                raise SoldOut("maximum serial number: "
                              "{0}".format(Tickets.MAX_NUMBER))

        sold = event.sold
        event.sold = sold + count
        session.commit()
        return sold, count

    @staticmethod
    def last_serial(session, event_name: str) -> int:
        query = session.query(Events)
        event = query.filter(Events.name == event_name).first()
        return event.sold

    def __init__(self, session, event: str, count: int = 1):
        last_serial, count = Tickets.generate_serial(session, event, count)
        self._count = count
        self._event = event
        self._issue = datetime.datetime.utcnow()
        self._serial = last_serial

    @property
    def count(self) -> int:
        return self._count

    @property
    def event(self) -> str:
        return self._event

    @property
    def issue(self) -> str:
        return self._issue.isoformat()

    @property
    def serial(self) -> int:
        return self._serial
