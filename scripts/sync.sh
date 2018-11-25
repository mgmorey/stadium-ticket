#!/bin/sh -eu

if which pipenv >/dev/null 2>&1; then
    pipenv sync "$@"
fi
