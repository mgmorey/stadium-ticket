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

install_packages() {
    install_opts=$("$script_dir/get-package-install-options.sh")
    installer=$("$script_dir/get-package-manager.sh")

    parse_arguments "$@"

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian|ubuntu|opensuse-*|fedora|redhat|centos)
		    install_pattern_from_args
		    install_packages_from_args
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    "$script_dir/install-homebrew.sh"
	    install_packages_from_args
	    ;;
	(FreeBSD|SunOS)
	    install_packages_from_args
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

install_packages_from_args() {
    if [ -n "$packages" ]; then
	$installer install $install_opts $packages
    fi
}

install_pattern_from_args() {
    if [ -n "$pattern" ]; then
	pattern_opts=$("$script_dir/get-pattern-install-options.sh")
	$installer install $install_opts $pattern_opts $pattern
    fi
}

parse_arguments() {
    packages=
    pattern=

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
    packages="$@"
}

usage() {
    if [ $# -gt 0 ]; then
	printf "$@" >&2
	printf "%s\n" "" >&2
    fi

    cat <<-EOF >&2
	Usage: $0: [-p PATTERN]
	       $0: -h
	EOF
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_packages "$@"
