#!/bin/sh -eux

# uninstall-app.sh: uninstall uWSGI application
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Set script directory
SCRIPT_DIR="$(dirname $0)"

# Set application parameters
. $SCRIPT_DIR/configure-app.sh

# Send interrupt signal to app
for i in 1 2 3 4 5 6; do
    if [ -r $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)

	if [ -n "$pid" ]; then
	    if sudo kill -s INT $pid; then
		sleep 5
	    else
		break
	    fi
	else
	    break
	fi
    else
	break
    fi
done

# Remove application and configuration
sudo /bin/rm -rf $APP_CONF_FILES $APP_DIR $APP_PIDFILE $APP_SOCKET $APP_VARDIR
