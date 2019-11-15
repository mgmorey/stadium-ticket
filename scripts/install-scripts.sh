#!/bin/sh -eu

# install-scripts: install scripts
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

abort() {
    printf "$@" >&2
    exit 1
}

if [ -h $0 ]; then
    abort "This script must be run as %s.\n" "$(realpath $0)"
fi

script_dir=$(pwd)
cd

if [ ! -d Documents/bin ]; then
    mkdir -m go-w -p Documents

    if [ -d bin ]; then
	/bin/mv bin Documents/bin
    else
	mkdir -m go-w Documents/bin
    fi
fi

if [ ! -e bin ]; then
    /bin/ln -s Documents/bin bin
fi

for file in bin/*; do
    if [ -h $file -a ! -e $file ]; then
	printf "Removing broken link: %s\n" "$file"
	/bin/rm -f $file
    fi
done

for file in "$script_dir"/*; do
    case "$(basename $file)" in
	(LICENSE|README*)
	    ;;
	(*)
	    if [ ! -e "bin/$(basename "$file")" ]; then
		ln -s "$file" bin
	    fi
	    ;;
    esac
done
