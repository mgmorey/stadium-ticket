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
OS_FILE=/etc/os-release

SHELL_FORMAT=false
USAGE="Usage: $(basename "$0"): [-a|-b|-h|-i|-k|-n|-p|-r]"
VARS_STANDARD="ID NAME PRETTY_NAME VERSION VERSION_ID"
VARS_EXTENDED="distro_name kernel_name kernel_release pretty_name release_name"

usage() {
    printf "%s\n" "$USAGE"
    exit 2
}

input=$(uname -sr)
kernel_name=${input% *}
kernel_release=${input#* }
shell_format=$SHELL_FORMAT
vars=

case "$kernel_name" in
    (Linux)
	. $OS_FILE
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

release_name=$kernel_release

while getopts Xhiknprvx opt
do
     case $opt in
	 (X)
	     shell_format=true
	     vars="$VARS_STANDARD $VARS_EXTENDED"
	     ;;
	 (h)
	     shell_format=false
	     vars="USAGE"
	     ;;
	 (i)
	     vars="${vars}${vars:+ }ID"
	     ;;
	 (k)
	     vars="${vars}${vars:+ }kernel_name"
	     ;;
	 (n)
	     vars="${vars}${vars:+ }NAME"
	     ;;
	 (p)
	     vars="${vars}${vars:+ }PRETTY_NAME"
	     ;;
	 (r)
	     vars="${vars}${vars:+ }kernel_release"
	     ;;
	 (v)
	     vars="${vars}${vars:+ }VERSION_ID"
	     ;;
	 (x)
	     shell_format=true
	     vars="$VARS_STANDARD"
	     ;;
	 (?)
	     usage
	     ;;
     esac
done

for var in ${vars:-PRETTY_NAME}; do
    eval val="\$$var"

    if [ "$shell_format" = true ]; then
	printf "%s=\"%s\"\n" "$var" "$val"
    else
	printf "%s\n" "$val"
    fi
done
