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

EVENT_1="The Beatles"
EVENT_2="The Cure"
EVENT_3="The Doors"
EVENT_4="The Who"
EVENT_5="SoldOut"
HEADER="Content-Type: application/json"

abort() {
    printf "$@" >&2
    exit 1
}

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
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$(pwd)

until [ "$source_dir" = / -o -r "$source_dir/.env" ]; do
    source_dir="$(dirname $source_dir)"
done

if [ "$source_dir" = / ]; then
    unset source_dir
fi

if [ -r "${source_dir+$source_dir/}.env" ]; then
    printf "%s\n" "Loading .env environment variables" >&2
    . "${source_dir+$source_dir/}.env"
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
url_tickets="$base_url/stadium/tickets"

for event in "$EVENT_1" "$EVENT_2" "$EVENT_3" "$EVENT_4" "$EVENT_5"; do
    add_event "$event" 1000
done

ab -H "$HEADER" -u "$script_dir/put.json" -n 1000 -r -c 10 $url_tickets
