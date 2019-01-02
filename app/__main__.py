# -*- coding: utf-8 -*-
"""Script to invoke the stadium tickets RESTful API."""

import click

from .flask_app import app, db


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


if __name__ == '__main__':
    cli()
