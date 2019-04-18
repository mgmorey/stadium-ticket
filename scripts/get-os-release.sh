#!/bin/sh -eu

# get-os-release: print OS distro/release information
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

FILE=/etc/release
FILE_OS=/etc/os-release
IS_SHELL_FORMAT=false
VARS_STANDARD="ID NAME PRETTY_NAME VERSION VERSION_ID"
VARS_EXTENDED="distro_name kernel_name kernel_release pretty_name release_name"

add_variable() {
    if [ $is_shell_format = false ]; then
	vars="${vars}${vars:+ }$1"
    else
	wrong_usage "%s: conflicting arguments\n" "$0"
    fi
}

set_variables() {
    if [ $is_shell_format = false -a -z "$vars" ]; then
	is_shell_format=true
	vars="$*"
    else
	wrong_usage "%s: conflicting arguments\n" "$0"
    fi
}

usage() {
    cat <<- EOM
	Usage: $0: [-i|-k|-n|-p|-r|-v]
	       $0: -x
	       $0: -X
	       $0: -h
	EOM
}

wrong_usage() {
    printf "$@" >&2
    printf "%s\n" ""
    usage
    exit 2
}

is_shell_format=$IS_SHELL_FORMAT
vars=

while getopts Xhiknprvx opt
do
    case $opt in
	(i)
	    add_variable ID
	    ;;
	(k)
	    add_variable kernel_name
	    ;;
	(n)
	    add_variable NAME
	    ;;
	(p)
	    add_variable PRETTY_NAME
	    ;;
	(r)
	    add_variable kernel_release
	    ;;
	(v)
	    add_variable VERSION_ID
	    ;;
	(x)
	    set_variables $VARS_STANDARD
	    ;;
	(X)
	    set_variables $VARS_STANDARD $VARS_EXTENDED
	    ;;
	(h)
	    usage
	    exit 0
	    ;;
	(\?)
	    printf "%s\n" ""
	    usage
	    exit 2
	    ;;
    esac
done

input=$(uname -sr)
kernel_name=${input% *}
kernel_release=${input#* }

case "$kernel_name" in
    (Linux)
	. $FILE_OS
	;;

    (SunOS)
	input=$(awk 'NR == 1 {printf("%s %s:%s\n", $1, $2, $3)}' $FILE)
	NAME=${input%:*}
	VERSION=${input#*:}
	ID=$(printf "%s\n" "${NAME% *}" | tr '[:upper:]' '[:lower:]')
	;;

    (Darwin)
	NAME=$(sw_vers -productName)
	VERSION=$(sw_vers -productVersion)
	ID=macos
	;;

    (CYGWIN_NT-*)
	kernel_release=$(printf "%s\n" "$kernel_release" | sed -e 's/(.*)//')
	NAME="Microsoft Windows"
	VERSION=${kernel_name#*-}
	ID=ms-windows
	VERSION_ID=$VERSION
	;;

    (*)
	NAME=$kernel_name
	VERSION=$kernel_release
	ID=$kernel_name
	VERSION_ID=$kernel_release
	PRETTY_NAME=$input
	;;

esac

if [ -z "${VERSION_ID-}" ]; then
    VERSION_ID="$VERSION"
fi

if [ -z "${PRETTY_NAME-}" ]; then
    PRETTY_NAME="$NAME $VERSION"
fi

distro_name=$ID
pretty_name=$PRETTY_NAME
release_name=$VERSION_ID

for var in ${vars:-PRETTY_NAME}; do
    eval val="\$$var"

    if [ "$is_shell_format" = true ]; then
	printf "%s=\"%s\"\n" "$var" "$val"
    else
	printf "%s\n" "$val"
    fi
done
