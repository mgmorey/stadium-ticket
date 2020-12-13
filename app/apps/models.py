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

"""Define data models for apps."""

from app.app import db


class Events(db.Model):
    """Represent one or more stadium events to which tickets are sold."""
    # pylint: disable=too-few-public-methods
    __tablename__ = 'events'
    name = db.Column(db.String(32), primary_key=True)
    sold = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Integer, nullable=False)

    def __repr__(self):
        return '<Events %r>' % self.name
