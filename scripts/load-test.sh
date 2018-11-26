#!/bin/sh -eu

# load-test: perform load test (stress test) on app
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

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

HEADER="Content-Type: application/json"
HOST=localhost
PORT=5000

URL_TICKET="http://${HOST}:${PORT}/stadium/ticket"
URL_TICKETS="http://${HOST}:${PORT}/stadium/tickets"

script_dir=$(dirname $0)
ab -H "$HEADER" -u $script_dir/put.json -n 1000 -r -c 10 $URL_TICKET
