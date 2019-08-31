#!/bin/sh -eu

# get-installed-packages: get a list of installed packages
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

DEBIAN_AWK='$1 = "install" && $2 == "ok" && $3 == "installed" {print $4}'

FREEBSD_AWK='{
n = split($1, a, "-");

for(i = 1; i < n; i++) {
    if (i > 1) {
	printf("-%s", a[i])}
    else {
	printf("%s", a[i])
    }
}

printf("\n")
}'

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_installed_packages() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian|ubuntu|linuxmint|neon)
		    dpkg-query -Wf '${Status} ${Package}\n' | awk "$DEBIAN_AWK"
		    ;;
		(opensuse-*)
		    zypper -q search -i -t package | awk 'NR > 3 {print $3}'
		    ;;
		(fedora)
		    dnf list installed | awk '{print $1}' | awk -F. '{print $1}'
		    ;;
		(ol|centos)
		    case "$VERSION_ID" in
			(7|7.*)
			    yum list installed | awk '{print $1}' | awk -F. '{print $1}'
			    /usr/pkg/bin/pkgin list | awk '{print ":" $1}'
			    ;;
			(8|8.*)
			    dnf list installed | awk '{print $1}' | awk -F. '{print $1}'
			    ;;
		    esac
		    ;;
	    esac
	    ;;
	(Darwin)
	    run_unpriv -c "/usr/local/bin/brew list -1"
	    pkgin list | awk '{print ":" $1}'
	    ;;
	(FreeBSD)
	    pkg info | awk "$FREEBSD_AWK"
	    ;;
	(NetBSD)
	    pkgin list | awk '{print $1}'
	    ;;
	(SunOS)
	    pkg list -s | awk '{print $1}'
	    pkgin list | awk '{print ":" $1}'
	    ;;
    esac
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

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/system-functions.sh"

eval $("$script_dir/get-os-release.sh" -X)

get_installed_packages
