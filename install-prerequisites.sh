#!/bin/sh -u

# install-prereuisites: install prerequisites
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

DEBIAN_PKGS="apache2-utils mariadb-server python3 python3-pip \
python3-pymysql python3-sqlalchemy python3-flask"

FEDORA_PKGS="httpd-tools mariadb python3 python3-pip \
python3-PyMySQL python3-sqlalchemy python3-flask"

FREEBSD_PKGS="apache24 mysql56-server python3 py36-pip \
py36-pymysql py36-sqlalchemy12 py36-Flask"

ILLUMOS_PKGS="apache-24 mariadb-101 python-34 pip-34 \
sqlalchemy-34"

SUSE_PKGS="apache2-utils mariadb python3 python3-pip \
python3-PyMySQL python3-SQLAlchemy python3-Flask"

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
		sudo apt-get install "$@" $DEBIAN_PKGS
		;;
	    (fedora)
		sudo dnf install "$@" $FEDORA_PKGS
		;;
	    (opensuse-*)
		sudo zypper install "$@" $SUSE_PKGS
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (FreeBSD)
	sudo pkg install "$@" $FREEBSD_PKGS
	;;
    (SunOS)
	sudo pkg install "$@" $ILLUMOS_PKGS
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac

python3 -m pip install --user -r requirements.txt
