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

EVENT_1="SoldOut"
EVENT_2="The Beatles"
EVENT_3="The Cure"
EVENT_4="The Doors"
EVENT_5="The Who"
HEADER="Content-Type: application/json"

abort() {
    printf "$@" >&2
    exit 1
}

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

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

script_dir=$(realpath "$(dirname "$0")")
source_dir=$script_dir/..

printf "%s\n" "Loading .env environment variables"
. $source_dir/.env

: ${DOCKER_HOST:=localhost}
host=${FLASK_HOST-${DOCKER_HOST%:*}}
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
url_ticket="$base_url/stadium/ticket"

for event in "$EVENT_1" "$EVENT_2" "$EVENT_3" "$EVENT_4" "$EVENT_5"; do
    add_event "$event" 1000
done

ab -H "$HEADER" -u "$script_dir/put.json" -n 1000 -r -c 10 $url_ticket
