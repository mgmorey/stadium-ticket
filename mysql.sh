#!/bin/sh

mysql -h ${MYSQL_HOST:=localhost} -u ${MYSQL_USER:-$USER} -p$MYSQL_PASSWORD "$@"
