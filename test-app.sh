#!/bin/sh

HEADER="Content-Type: application/json"
TICKET=http://localhost:5000/stadium/ticket
TICKETS=http://localhost:5000/stadium/tickets

curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "event": "The Beatles"}' -i $TICKET
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 10, "event": "The Cure"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
curl -i -H "$HEADER" -X PUT -d '{"command": "request_ticket", "count": 100, "event": "The Doors"}' -i $TICKETS
