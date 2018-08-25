#!/bin/sh

HEADER="Content-Type: application/json"
TICKET=http://localhost:5000/stadium/ticket

ab -H "$HEADER" -u put.json -n 1000 -r -c 10 $TICKET
