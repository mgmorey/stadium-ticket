#!/bin/sh -eu

if which pipenv >/dev/null 2>&1; then
    if [ "$1" = -s -o "$1" = --sync ]; then
	pipenv sync
	shift
    fi

    pipenv run "$@"
else
    "$@"
fi
