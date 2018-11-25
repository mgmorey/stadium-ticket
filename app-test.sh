#!/bin/sh -eu

HEADER="Content-Type: application/json"
HOST=localhost
PORT=5000

URL_TICKET="http://${HOST}:${PORT}/stadium/ticket"
URL_TICKETS="http://${HOST}:${PORT}/stadium/tickets"

curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "event": "The Beatles"}' -i $URL_TICKET
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 10, "event": "The Cure"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $URL_TICKETS
