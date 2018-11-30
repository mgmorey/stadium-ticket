# -*- coding: utf-8 -*-

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session

from .uri import get_uri

engine = create_engine(get_uri())

Base = declarative_base()
Base.metadata.bind = engine


def get_session():
    return scoped_session(sessionmaker(bind=engine))
