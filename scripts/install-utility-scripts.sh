#!/bin/sh -eu

# install-utility-scripts: install utility scripts
# Copyright (C) 2019  "Michael G. Morey" <mgmorey@gmail.com>

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

BASE_URL=https://github.com/mgmorey
PROJECT=utility-scripts

UTILITY_SCRIPTS_URL=$BASE_URL/$PROJECT.git

create_git_directory() {
    cd

    if [ ! -d Documents/git ]; then
	mkdir -p Documents

	if [ -d git ]; then
	    /bin/mv git Documents/git
	else
	    mkdir Documents/git
	fi
    fi

    if [ ! -e git ]; then
	/bin/ln -s Documents/git git
    fi
}

install_utility_scripts() {
    create_git_directory
    cd git

    if [ -d $PROJECT ]; then
	cd $PROJECT
	git pull origin master
    else
	git clone $UTILITY_SCRIPTS_URL
	cd $PROJECT
    fi

    ./install-scripts
}

install_utility_scripts
