# -*- coding: utf-8 -*-
# Copyright (C) 2020  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""Script to invoke the stadium tickets RESTful API."""

import click

from .flask_app import app, db


def _format_parameter(key, value):
    return "{}='{}'".format(key, value)


@click.group()
def cli():
    """Create Click group named cli."""


@cli.command()
def create_database():
    """Create database schema and tables."""
    click.echo('Creating the database')
    with app.app_context():
        db.create_all()
    click.echo('Created the database')


@cli.command()
def drop_database():
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
