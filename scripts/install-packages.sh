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

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
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

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

script_dir=$(realpath "$(dirname "$0")")

eval $(sh -eu $script_dir/get-os-release.sh -X)

package_install_options=$(sh -eu $script_dir/get-package-install-options.sh)
package_manager=$(sh -eu $script_dir/get-package-manager.sh)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu|centos|fedora|readhat|opensuse-*)
		;;
	    (*)
		abort "%s: Distro not supported\n" "$pretty_name"
		;;
	esac
	;;
    (Darwin)
	sh -eu $script_dir/install-homebrew.sh
	;;
    (FreeBSD|SunOS)
	;;
    (*)
	abort "%s: Operating system not supported\n" "$pretty_name"
	;;
esac

$package_manager install $package_install_options "$@"
