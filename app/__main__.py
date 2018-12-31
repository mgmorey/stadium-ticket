# -*- coding: utf-8 -*-
"""Script to invoke the stadium tickets RESTful API."""

import logging

import click

from .apps import Events
from .flask_app import LOGGING_FORMAT, app, db


@click.group()
def cli():
    """Create Click group named cli."""


@cli.command()
def drop_db():
    """Drop database schema and tables."""
    click.echo('Dropping the database')
    with app.app_context():
        db.drop_all()
    click.echo('Dropped the database')


@cli.command()
def init_db():
    """Create database schema and tables."""
    click.echo('Initializing the database')
    with app.app_context():
        db.create_all()
    click.echo('Initialized the database')


@cli.command()
def load_db():
    """Create database schema and tables."""
    click.echo('Loading the database with test data')
    with app.app_context():
        db.session.add(Events(name='SoldOut', sold=0, total=1000))
        db.session.add(Events(name='The Beatles', sold=0, total=1000))
        db.session.add(Events(name='The Cure', sold=0, total=1000))
        db.session.add(Events(name='The Doors', sold=0, total=1000))
        db.session.add(Events(name='The Who', sold=0, total=1000))
        db.session.commit()
    click.echo('Loaded the database with test data')


if __name__ == '__main__':
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    cli()
