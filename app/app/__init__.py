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

"""Define db object and app creation factory method."""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()  # pylint: disable=invalid-name


def create_app(config_name):
    """Return an app object."""
    app = Flask(__name__)
    app.config.from_object(config_name)
    db.init_app(app)
    return app
