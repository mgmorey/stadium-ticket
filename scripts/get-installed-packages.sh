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

DPKG_AWK='$1 = "install" && $2 == "ok" && $3 == "installed" {print $4}'

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

PREFIX_AWK='{printf("%s%s\n", prefix, $0)}'

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_installed_packages() {
    prefix=

    for manager; do
	if ! which $manager >/dev/null 2>&1; then
	    continue
	fi

	(get_packages_using $manager || true) | prefix_lines "$prefix"
	prefix=:
    done
}

get_packages_using() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "$(basename $1)" in
	(apt-get)
	    dpkg-query -Wf '${Status} ${Package}\n' | awk "$DPKG_AWK"
	    ;;
	(brew)
	    run_unpriv /bin/sh -c "$1 list -1"
	    ;;
	(dnf)
	    $1 list installed | awk 'NF == 3 {print $1}' | awk -F. '{print $1}'
	    ;;
	(pkg)
	    case "$ID" in
		(freebsd)
		    $1 info --all | awk "$FREEBSD_AWK"
		    ;;
		(*)
		    $1 list | awk 'NR > 1 {print $1}'
		    ;;
	    esac
	    ;;
	(pkgin)
	    $1 list | awk '{print $1}'
	    ;;
	(pkgutil)
	    $1 --list | awk '{print $1}'
	    ;;
	(yum)
	    $1 list installed | awk 'NF == 3 {print $1}' | awk -F. '{print $1}'
	    ;;
	(zypper)
	    $1 -q search -i -t package | awk 'NR > 3 {print $3}'
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

prefix_lines() {
    assert [ $# -eq 1 ]
    awk -v prefix=$1 "$PREFIX_AWK"
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -x)

. "$script_dir/system-functions.sh"

managers=$("$script_dir/get-package-managers.sh")
get_installed_packages $managers
