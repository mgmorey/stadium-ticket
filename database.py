# -*- coding: utf-8 -*-

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session

from connection import get_connection

engine = create_engine(get_connection())
session = scoped_session(sessionmaker(bind=engine))

Base = declarative_base()
Base.metadata.bind = engine
