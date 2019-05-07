#!/bin/sh -eu

# start-uwsgi.sh: run Flask application using uWSGI
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

APP_NAME=stadium-ticket
PREFIX=/usr/local/opt/uwsgi

APP_ETCDIR=/usr/local/etc/opt/$APP_NAME
OBJECT_DIR=$PREFIX/lib/plugin

PLUGIN=python3_plugin.so

if uwsgi --version >/dev/null 2>&1; then
    if [ -x $OBJECT_DIR/$PLUGIN ]; then
	if cd $OBJECT_DIR; then
	    uwsgi $APP_ETCDIR/app.ini
	fi
    fi
fi
