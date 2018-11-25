#!/bin/sh -eu

if which pipenv >/dev/null; then
    if [ "$1" = -s -o "$1" = --sync ]; then
	pipenv sync
    fi

    pipenv run "$@"
else
    "$@"
fi
