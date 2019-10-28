#!/bin/sh -eu

# get-uwsgi-packages: get uWSGI app server package names
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

DARWIN_PKGS=":%s-uwsgi"

DEBIAN_10_PKGS="util-linux uwsgi uwsgi-plugin-%s"

FEDORA_PKGS="util-linux uwsgi uwsgi-plugin-%s"

FREEBSD_PKGS="uwsgi"

NETBSD_PKGS="%s-uwsgi"

OPENSUSE_PKGS="system-user-wwwrun util-linux uwsgi uwsgi-%s"

REDHAT_7_PKGS=":%s-uwsgi"
REDHAT_8_PKGS="util-linux uwsgi uwsgi-plugin-%s"

SUNOS_PKGS=":%s-uwsgi"

UBUNTU_18_PKGS="setpriv uwsgi uwsgi-plugin-%s"
UBUNTU_19_PKGS=$DEBIAN_10_PKGS

abort() {
    printf "$@" >&2
    exit 1
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

get_uwsgi_packages() {
    case "$kernel_name" in
	(Linux|GNU)
	    case "$ID" in
		(debian|raspbian)
		    case "$VERSION_ID" in
			(10)
			    packages=$DEBIAN_10_PKGS
			    ;;
		    esac
		    ;;
		(ubuntu|neon)
		    case "$VERSION_ID" in
			(18.04)
			    packages=$UBUNTU_18_PKGS
			    ;;
			(19.04)
			    packages=$UBUNTU_19_PKGS
			    ;;
			(19.10)
			    packages=$UBUNTU_19_PKGS
			    ;;
		    esac
		    ;;
		(linuxmint)
		    case "$VERSION_ID" in
			(19.2)
			    packages=$UBUNTU_18_PKGS
			    ;;
		    esac
		    ;;
		(kali)
		    case "$VERSION_ID" in
			(2019.3)
			    packages=$DEBIAN_10_PKGS
			    ;;
		    esac
		    ;;
		(opensuse-*)
		    packages=$OPENSUSE_PKGS
		    ;;
		(fedora)
		    packages=$FEDORA_PKGS
		    ;;
		(rhel|ol|centos)
		    case "$VERSION_ID" in
			(7|7.[78])
			    packages=$REDHAT_7_PKGS
			    ;;
			(8|8.[01])
			    packages=$REDHAT_8_PKGS
			    ;;
		    esac
		    ;;
	    esac
	    ;;
	(Darwin)
	    packages=$DARWIN_PKGS
	    ;;
	(FreeBSD)
	    packages=$FREEBSD_PKGS
	    ;;
	(NetBSD)
	    packages=$NETBSD_PKGS
	    ;;
	(SunOS)
	    packages=$SUNOS_PKGS
	    ;;
    esac

    "$script_dir/get-python-packages.sh" ${packages-}
}

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

get_uwsgi_packages
