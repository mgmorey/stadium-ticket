#!/bin/sh -eu

# uninstall-packages: uninstall packages
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

abort() {
    printf "$@" >&2
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_manager() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 -ge 1 -a -$1 -le 2 ]
    printf "%s\n" $managers | awk 'NR == '"$1"' {print $0}'
}

get_packages() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 -ge 1 -a -$1 -le 2 ]

    case "$1" in
	(1)
	    awk_expr='NF == 1 {print $0} NF == 2 {print $1}'
	    ;;
	(2)
	    awk_expr='NF == 2 {print $2}'
	    ;;
    esac

    printf "%s\n" $packages | awk -F: "$awk_expr"
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

invoke_manager() (
    if [ "$1" = /usr/local/bin/brew ]; then
	run_unpriv -c "$*"
    else
	"$@"
    fi
)

parse_arguments() {
    packages="$@"
}

uninstall_packages() {
    validate_platform
    managers=$("$script_dir/get-package-managers.sh")

    if [ $# -eq 0 ]; then
	return 0
    fi

    parse_arguments "$@"
    uninstall_packages_from_args
}

uninstall_packages_from_args() (
    if [ -z "$packages" ]; then
	return 0
    fi

    index=1

    while [ $index -le 2 ]; do
	uninstall_using "$(get_manager $index)" remove \
			$(get_packages $index)
	index=$((index + 1))
    done
)

uninstall_using() (
    assert [ $# -ge 2 ]

    if [ $# -eq 2 ]; then
	return 0
    elif [ -z "$1" ]; then
	return 0
    fi

    uninstaller=$1
    uninstaller_command=$2
    shift 2

    if [ "$uninstaller" = /usr/local/bin/brew ]; then
	run_unpriv -c "$uninstaller $uninstaller_command $*"
    else
	$uninstaller $uninstaller_command "$@"
    fi
)

validate_platform() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu|linuxmint|neon|kali)
		    :
		    ;;
		(opensuse-*|fedora|ol|centos)
		    :
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    :
	    ;;
	(FreeBSD)
	    :
	    ;;
	(NetBSD)
	    :
	    ;;
	(SunOS)
	    :
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

uninstall_packages "$@"