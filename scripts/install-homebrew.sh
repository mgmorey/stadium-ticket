#!/bin/sh -u

# install-homebrew: install HomeBrew (for Darwin platform)
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

HOMEBREW_URL=https://raw.githubusercontent.com/Homebrew/install/master/install

if ! brew info >/dev/null 2>&1; then
    /usr/bin/ruby -e $expr "$(curl -fsSL $HOMEBREW_URL)"
fi
