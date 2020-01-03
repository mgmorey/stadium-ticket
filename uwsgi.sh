#!/bin/sh -eu

if [ $# -gt 0 ]; then
    "$@"
fi

uwsgi --ini $APP_INIFILE
