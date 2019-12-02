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

configure_platform() {
    is_pattern_supported=false

    for id in $ID $ID_LIKE; do
	case "$id" in
	    (centos)
		is_pattern_supported=true

		case "$VERSION_ID" in
		    (7)
			"$script_dir/install-epel.sh"
			;;
		    (8)
			"$script_dir/install-epel.sh"
			;;
		esac
		break
		;;
	    (debian)
		is_pattern_supported=true
		break
		;;
	    (fedora)
		is_pattern_supported=true
		break
		;;
	    (rhel|ol)
		is_pattern_supported=true

		case "$VERSION_ID" in
		    (7.*)
			"$script_dir/install-epel.sh"
			;;
		    (8.*)
			"$script_dir/install-epel.sh"
			;;
		esac
		break
		;;
	    (solaris)
		"$script_dir/set-publisher-sfe.sh"
		break
		;;
	esac
    done
}

get_manager() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 -ge 1 -a -$1 -le 2 ]
    printf "%s\n" $managers | awk 'NR == '"$1"' {print $0}'
}

get_options() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ $1 -ge 1 -a -$1 -le 2 ]
    printf "%s\n" $options | awk 'NR == '"$1"' {print $0}'
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

install_packages() {
    validate_platform
    configure_platform
    managers=$("$script_dir/get-package-managers.sh")
    options=$("$script_dir/get-package-install-options.sh")

    if [ $# -eq 0 ]; then
	return 0
    fi

    parse_arguments "$@"
    "$script_dir/install-package-managers.sh" $managers

    if [ "$is_pattern_supported" = true ]; then
	install_pattern_from_args
    fi

    install_packages_from_args
}

install_packages_from_args() (
    if [ -z "$packages" ]; then
	return 0
    fi

    index=1

    while [ $index -le 2 ]; do
	install_packages_using "$(get_manager $index)" \
			       "$(get_options $index)" \
			       $(get_packages $index)
	index=$((index + 1))
    done
)

install_packages_using() (
    assert [ $# -ge 2 ]

    if [ $# -eq 2 ]; then
	return 0
    elif [ -z "$1" ]; then
	return 0
    fi

    manager=$1
    options=$2
    shift 2

    install=$("$script_dir/get-install-command.sh" $manager)

    case "$(basename $manager)" in
	(brew)
	    run_unpriv /bin/sh -c "$manager $install $options $*"
	    ;;
	(*)
	    $manager $install $options $*
	    ;;
    esac
)

install_pattern_from_args() (
    if [ -z "$pattern" ]; then
	return 0
    fi

    install_pattern_using "$(get_manager 1)" "$options" "$pattern"
)

install_pattern_using() (
    assert [ $# -ge 2 ]

    if [ $# -eq 2 ]; then
	return 0
    elif [ -z "$1" ]; then
	return 0
    fi

    manager=$1
    options=$2
    shift 2

    install=$("$script_dir/get-pattern-install-command.sh" $manager)

    case "$(basename $manager)" in
	(brew)
	    run_unpriv /bin/sh -c "$manager $install $options \"$1\""
	    ;;
	(*)
	    $manager $install $options "$1"
	    ;;
    esac
)

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

validate_platform() {
    for id in $ID $ID_LIKE; do
	case "$id" in
	    (debian)
		return
		;;
	    (fedora)
		return
		;;
	    (opensuse)
		return
		;;
	    (rhel|ol|centos)
		case "$VERSION_ID" in
		    (7|7.*)
			return
			;;
		    (8|8.*)
			return
			;;
		esac
		;;
	    (darwin)
		return
		;;
	    (freebsd)
		return
		;;
	    (netbsd)
		return
		;;
	    (illumos)
		return
		;;
	    (solaris)
		return
		;;
	esac
    done

    abort_not_supported "Operating system"
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -x)

. "$script_dir/system-functions.sh"

install_packages "$@"
