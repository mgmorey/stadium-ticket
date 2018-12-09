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

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu)
		dpkg-query -Wf '${Package}\n'
		;;
	    (redhat|centos|fedora)
		yum list installed | awk '{print $1}' | awk -F. '{print $1}'
		;;
	    (opensuse-*)
		zypper -q search -i -t package | awk 'NR > 3 {print $3}'
		;;
	esac
	;;
    (FreeBSD)
	pkg info | awk "$FREEBSD_AWK"
	;;
    (SunOS)
	pkg list -s | awk '{print $1}'
	;;
esac
