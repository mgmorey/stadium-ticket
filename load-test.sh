#!/bin/sh

HEADER="Content-Type: application/json"
HOST=localhost
PORT=5000

URL_TICKET="http://${HOST}:${PORT}/stadium/ticket"
URL_TICKETS="http://${HOST}:${PORT}/stadium/tickets"

script_dir=$(dirname $0)/scripts
ab -H "$HEADER" -u $script_dir/put.json -n 1000 -r -c 10 $URL_TICKET
