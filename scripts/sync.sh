#!/bin/sh -eu

if which pipenv >/dev/null; then
    pipenv sync
fi
