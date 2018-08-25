# -*- coding: utf-8 -*-

import datetime
import json

from sqlalchemy import Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

Base = declarative_base()
engine = create_engine("mysql+pymysql://mgmorey:Front.242!"
                       "@localhost/stadium-tickets")
session_obj = sessionmaker(bind=engine)
session = scoped_session(session_obj)
Base.metadata.bind = engine


class Event(Base):
    __tablename__ = 'events'
    name = Column(String(32), primary_key=True)
    sold = Column(Integer, nullable=False)
    total = Column(Integer, nullable=False)


class SoldOut(Exception):
    pass


class Tickets(object):
    EVENTS = 'events.json'
    FMT_NUMBER = 'maximum serial number: {}'
    MAX_NUMBER = 1000

    # events = {}

    @staticmethod
    def generate_serial(event_name: str, count: int = 1):
        query = session.query(Event)
        event = query.filter(Event.name == event_name).first()
        last_serial = event.sold

        if Tickets.MAX_NUMBER is not None:
            if last_serial + count > Tickets.MAX_NUMBER:
                raise SoldOut(Tickets.FMT_NUMBER.format(Tickets.MAX_NUMBER))

        event.sold = event.sold + count
        session.commit()

    @staticmethod
    def last_serial(event_name: str) -> int:
        query = session.query(Event)
        event = query.filter(Event.name == event_name).first()
        return event.sold

    @staticmethod
    def load():
        pass

    @staticmethod
    def save():
        pass

    def __init__(self, event: str, count: int = 1):
        last_serial = Tickets.last_serial(event)
        Tickets.generate_serial(event, count)
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
