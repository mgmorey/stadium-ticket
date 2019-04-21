#!/bin/sh -u

# install-packages: install packages
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

install_packages() {
    install_opts=$(sh -eu $script_dir/get-package-install-options.sh)
    installer=$(sh -eu $script_dir/get-package-manager.sh)

    if [ -n "${pattern-}" ]; then
	pattern_opts=$(sh -eu $script_dir/get-pattern-install-options.sh)
	$installer install $install_opts $pattern_opts $pattern
    fi

    $installer install $install_opts "$@"
}

parse_arguments() {
    while getopts hp: opt; do
	case $opt in
	    (p)
		pattern=$OPTARG
		;;
	    (h)
		usage
		exit 0
		;;
	    (\?)
		printf "%s\n" "" >&2
		usage
		exit 2
		;;
	esac
    done

    shift $(($OPTIND - 1))
}

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

usage() {
    if [ $# -gt 0 ]; then
	printf "$@" >&2
	printf "%s\n" "" >&2
    fi

    cat >&2 <<-EOM
	Usage: $0: [-p PATTERN]
	       $0: -h
	EOM
}

parse_arguments

script_dir=$(realpath "$(dirname "$0")")

eval $(sh -eu $script_dir/get-os-release.sh -X)

case "$kernel_name" in
    (Linux)
	case "$ID" in
	    (debian|ubuntu|centos|fedora|readhat|opensuse-*)
		install_packages
		;;
	    (*)
		abort_not_supported Distro
		;;
	esac
	;;
    (Darwin)
	sh -eu $script_dir/install-homebrew.sh
	install_packages
	;;
    (FreeBSD|SunOS)
	install_packages
	;;
    (*)
	abort_not_supported "Operating system"
	;;
esac
