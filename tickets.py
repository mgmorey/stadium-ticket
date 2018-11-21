# -*- coding: utf-8 -*-

import datetime

from sqlalchemy import Column, Integer, String, create_engine

from database import Base, engine, session


class Tickets(object):
    MAX_NUMBER = 1000

    class Events(Base):
        __tablename__ = 'events'
        name = Column(String(32), primary_key=True)
        sold = Column(Integer, nullable=False)
        total = Column(Integer, nullable=False)

    class SoldOut(Exception):
        pass

    @staticmethod
    def generate_serial(event_name: str, count: int = 1):
        query = session.query(Tickets.Events)
        event = query.filter(Tickets.Events.name == event_name).first()
        last_serial = event.sold

        if Tickets.MAX_NUMBER is not None:
            if last_serial + count > Tickets.MAX_NUMBER:
                raise Tickets.SoldOut("maximum serial number: "
                                      "{0}".format(Tickets.MAX_NUMBER))

        sold = event.sold
        event.sold = sold + count
        session.commit()
        return sold, count

    @staticmethod
    def last_serial(event_name: str) -> int:
        query = session.query(Tickets.Events)
        event = query.filter(Tickets.Events.name == event_name).first()
        return event.sold

    def __init__(self, event: str, count: int = 1):
        last_serial, count = Tickets.generate_serial(event, count)
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
