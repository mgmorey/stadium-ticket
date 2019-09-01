#!/bin/sh -eu

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
    installers=$("$script_dir/get-package-manager.sh")
    installer1=$(printf "%s\n" $installers | awk 'NR == 1 {print $0}')
    installer2=$(printf "%s\n" $installers | awk 'NR == 2 {print $0}')

    parse_arguments "$@"

    if [ -n "$packages" ]; then
	packages1=$(printf "%s\n" $packages | awk -F: 'NF == 1 {print $0}
						       NF == 2 {print $1}')
	packages2=$(printf "%s\n" $packages | awk -F: 'NF == 2 {print $2}')
    fi

    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu|linuxmint|neon)
		    install_pattern_from_args
		    install_packages_from_args
		    ;;
		(opensuse-*|fedora|ol|centos)
		    install_pattern_from_args
		    install_packages_from_args
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    install_packages_from_args
	    ;;
	(FreeBSD)
	    install_packages_from_args
	    ;;
	(NetBSD)
	    install_packages_from_args
	    ;;
	(SunOS)
	    install_packages_from_args
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac
}

install_packages_from_args() {
    if [ -z "$packages" ]; then
	return 0
    fi

    if [ -n "$installer1" -a -n "$packages1" ]; then
	invoke_installer $installer1 install $install_opts $packages1
    fi

    if [ -n "$installer2" -a -n "$packages2" ]; then
	if [ -n "$(which $installer2 2>/dev/null)" ]; then
	    invoke_installer $installer2 install $packages2
	fi
    fi
}

install_pattern_from_args() {
    if [ -z "$pattern" ]; then
	return 0
    fi

    pattern_opts=$("$script_dir/get-pattern-install-options.sh")
    invoke_installer $installer1 install $install_opts $pattern_opts $pattern
}

invoke_installer() (
    if [ "$1" = /usr/local/bin/brew ]; then
	run_unpriv -c "$*"
    else
	"$@"
    fi
)

parse_arguments() {
    packages=
    pattern=

    while getopts hp: opt; do
	case $opt in
	    (p)
		pattern=$("$script_dir/get-uninstalled-packages.sh" $OPTARG)
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
    packages=$("$script_dir/get-uninstalled-packages.sh" "$@")
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

. "$script_dir/system-functions.sh"

eval $("$script_dir/get-os-release.sh" -X)

install_packages "$@"
