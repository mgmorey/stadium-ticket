#!/bin/sh -eu

if which pipenv >/dev/null; then
    pipenv sync
    pipenv run "$@"
else
    "$@"
fi
