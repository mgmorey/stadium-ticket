#!/bin/sh -eu

# app-test: client script to test app server
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
HOST=${FLASK_HOST:-localhost}
PORT=${FLASK_PORT:-5000}

while getopts 'h:p:' OPTION; do
    case $OPTION in
	('h')
	    HOST="$OPTARG"
	    ;;
	('p')
	    PORT="$OPTARG"
	    ;;
	('?')
	    printf "Usage: %s: [-h <HOST>] [-p <PORT]\n" $(basename $0) >&2
	    exit 2
	    ;;
    esac
done
shift $(($OPTIND - 1))

base_url="http://${HOST}${PORT:+:}${PORT}"
url_ticket="$base_url/stadium/ticket"
url_tickets="$base_url/stadium/tickets"

curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "event": "The Beatles"}' -i $url_ticket
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 10, "event": "The Cure"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $url_tickets
