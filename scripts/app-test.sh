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

EVENT_1="The Beatles"
EVENT_2="The Cure"
EVENT_3="The Doors"
EVENT_4="The Who"
EVENT_5="SoldOut"
HEADER="Content-Type: application/json"

add_event() {
    curl -H "$HEADER" -X PUT -d @- -i $url_event <<-EOF
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

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

list_event() {
    name=$(printf "%s\n" "$1" | sed -e 's/ /%20/g')
    curl -H "$HEADER" -X GET -i "${url_event}?name=$name"
}

list_events() {
    curl -H "$HEADER" -X GET -i $url_events
}

remove_event() {
    name=$(printf "%s\n" "$1" | tr -ds ' ' '%20')
    curl -H "$HEADER" -X DELETE -i "${url_event}?name=$name"
}

request_tickets() {
    curl -H "$HEADER" -X POST -d @- -i $url_tickets <<-EOF
	{
	    "command": "request_tickets",
	    "event": "$1",
	    "count": $2
	}
	EOF
}

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$script_dir/..

if [ -r "source_dir/.env" ]; then
    printf "%s\n" "Loading .env environment variables"
    . "$source_dir/.env"
fi

host=${FLASK_HOST-localhost}
port=${FLASK_PORT-5000}

while getopts h:p: opt; do
    case $opt in
	(h)
	    host="$OPTARG"
	    ;;
	(p)
	    port="$OPTARG"
	    ;;
	(\?)
	    printf "Usage: %s: [-h <HOST>] [-p <PORT]\n" "$0" >&2
	    exit 2
	    ;;
    esac
done

shift $(($OPTIND - 1))

base_url="http://${host}${port:+:}${port}"
url_event="$base_url/stadium/event"
url_events="$base_url/stadium/events"
url_tickets="$base_url/stadium/tickets"

add_event "$EVENT_1" 1000
list_event "$EVENT_1"
remove_event "$EVENT_1"

for event in "$EVENT_1" "$EVENT_2" "$EVENT_3" "$EVENT_4" "$EVENT_5"; do
    add_event "$event" 1000
done

list_events
request_tickets "The Beatles" 1
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
