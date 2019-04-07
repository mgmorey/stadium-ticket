#!/bin/sh -eu

# clean-virtualenvs: remove Python 3 virtual environments
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

PYTHON=python3

for pipenv in pipenv "$PYTHON -m pipenv" false; do
    if $pipenv >/dev/null 2>&1; then
	break
    fi
done

if [ "$pipenv" != false ]; then
    $pipenv --rm
fi

/bin/rm -rf .venv*

