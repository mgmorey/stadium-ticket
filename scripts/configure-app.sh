#!/bin/sh -eux

# configure-app: open application configuration in a text editor
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

tmpfile=$(mktemp -p .)
trap "/bin/rm -f $tmpfile ${tmpfile}~" INT QUIT TERM

if [ -r .env ]; then
    cp -f .env $tmpfile
elif [ -r .env-template ]; then
    cp -f .env-template $tmpfile
fi

if $EDITOR $tmpfile; then
   mv -f $tmpfile .env
fi
