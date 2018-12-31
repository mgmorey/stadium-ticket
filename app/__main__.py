# -*- coding: utf-8 -*-
"""Script to invoke the stadium tickets RESTful API."""

import logging

import click

from .apps import Events
from .flask_app import LOGGING_FORMAT, app, db


def _load_data(session):
    session.add(Events(name='SoldOut', sold=0, total=1000))
    session.add(Events(name='The Beatles', sold=0, total=1000))
    session.add(Events(name='The Cure', sold=0, total=1000))
    session.add(Events(name='The Doors', sold=0, total=1000))
    session.add(Events(name='The Who', sold=0, total=1000))
    session.commit()


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
    """Load the database with test data."""
    click.echo('Loading the database with test data')
    with app.app_context():
        _load_data(db.session)
    click.echo('Loaded the database with test data')


@cli.command()
def reload_db():
    """Reload the database with test data."""
    click.echo('Reloading the database with test data')
    with app.app_context():
        db.drop_all()
        db.create_all()
        _load_data(db.session)
    click.echo('Reloaded the database with test data')


if __name__ == '__main__':
    logging.basicConfig(format=LOGGING_FORMAT, level=logging.DEBUG)
    cli()
