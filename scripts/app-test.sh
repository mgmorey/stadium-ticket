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

EVENT_1="SoldOut"
EVENT_2="The Beatles"
EVENT_3="The Cure"
EVENT_4="The Doors"
EVENT_5="The Who"
HEADER="Content-Type: application/json"

add_event() {
    curl -H "$HEADER" -X PUT -d @- -i $url_event <<EOF
{
	"command": "add_event",
	"event": "$1",
	"total": $2
}
EOF
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

list_events() {
    curl -H "$HEADER" -X GET -i $url_events
}

request_ticket() {
    curl -H "$HEADER" -X PUT -d @- -i $url_ticket <<EOF
{
	"command": "request_ticket",
	"event": "$1"
}
EOF
}

request_tickets() {
    curl -H "$HEADER" -X PUT -d @- -i $url_tickets <<EOF
{
	"command": "request_ticket",
	"event": "$1",
	"count": $2
}
EOF
}

script_dir=$(get_path "$(dirname "$0")")

source_dir=$script_dir/..

printf "%s\n" "Loading .env environment variables"
. "$source_dir/.env"

host=${FLASK_HOST-localhost}
port=${FLASK_PORT-5000}

while getopts 'h:p:' OPTION; do
    case $OPTION in
	('h')
	    host="$OPTARG"
	    ;;
	('p')
	    port="$OPTARG"
	    ;;
	('?')
	    printf "Usage: %s: [-h <HOST>] [-p <PORT]\n" $(basename $0) >&2
	    exit 2
	    ;;
    esac
done

shift $(($OPTIND - 1))

base_url="http://${host}${port:+:}${port}"
url_event="$base_url/stadium/event"
url_events="$base_url/stadium/events"
url_ticket="$base_url/stadium/ticket"
url_tickets="$base_url/stadium/tickets"

for event in "$EVENT_1" "$EVENT_2" "$EVENT_3" "$EVENT_4" "$EVENT_5"; do
    add_event "$event" 1000
done

list_events
request_ticket "The Beatles"
request_tickets "The Cure" 10
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
request_tickets "The Doors" 100
