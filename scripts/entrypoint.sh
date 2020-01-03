#!/bin/sh -eu

pipenv run create-database
/usr/bin/uwsgi "$@"
