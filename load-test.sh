#!/bin/sh

HEADER="Content-Type: application/json"
HOST=localhost
PORT=5000

URL=http://$HOST:$PORT/stadium/ticket

ab -H "$HEADER" -u put.json -n 1000 -r -c 10 $URL
