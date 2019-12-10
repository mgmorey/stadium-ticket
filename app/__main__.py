# -*- coding: utf-8 -*-
"""Script to invoke the stadium tickets RESTful API."""

import click

from .flask_app import app, db


def _format_parameter(key, value):
    return f"{key}='{value}'"


@click.group()
def cli():
    """Create Click group named cli."""


@cli.command()
def create_db():
    """Create database schema and tables."""
    click.echo('Creating the database')
    with app.app_context():
        db.create_all()
    click.echo('Created the database')


@cli.command()
def drop_db():
    """Drop database schema and tables."""
    click.echo('Dropping the database')
    with app.app_context():
        db.drop_all()
    click.echo('Dropped the database')


@cli.command()
def get_parameters():
    """Print application parameter values."""
    for key, value in app.config.items():
        click.echo(_format_parameter(key, value))


if __name__ == '__main__':
    cli()
