#!/bin/sh

# install-pkgsrc: install the portable package build system
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

DARWIN_BOOT_OS=Darwin
DARWIN_BOOT_PGP=1F32A9AD
DARWIN_BOOT_SHA=1c554a806fb41dcc382ef33e64841ace13988479
DARWIN_BOOT_TAR=bootstrap-trunk-x86_64-20190524.tar.gz

ILLUMOS_BOOT_OS=SmartOS
ILLUMOS_BOOT_PGP=DE817B8E
ILLUMOS_BOOT_SHA=cda0f6cd27b2d8644e24bc54d19e489d89786ea7
ILLUMOS_BOOT_TAR=bootstrap-trunk-x86_64-20190317.tar.gz

REDHAT_BOOT_OS=Linux/el7
REDHAT_BOOT_PGP=56AAACAF
REDHAT_BOOT_SHA=eb0d6911489579ca893f67f8a528ecd02137d43a
REDHAT_BOOT_TAR=bootstrap-trunk-x86_64-20170127.tar.gz

URL=https://pkgsrc.joyent.com

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

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
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

install_pkgsrc() {
    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(ol)
		    case "$VERSION_ID" in
			(7.7)
			    key=REDHAT
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(centos)
		    case "$VERSION_ID" in
			(7)
			    key=REDHAT
			    ;;
			(*)
			    abort_not_supported Release
			    ;;
		    esac
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    case "$VERSION_ID" in
		(10.14.*)
		    key=DARWIN
		    ;;
		(*)
		    abort_not_supported Release
		    ;;
	    esac
	    ;;
	(SunOS)
	    key=ILLUMOS
	    ;;
	(*)
	    abort_not_supported "Operating system"
	    ;;
    esac

    boot_os="\${${key}_BOOT_OS}"
    boot_pgp="\${${key}_BOOT_PGP}"
    boot_sha="\${${key}_BOOT_SHA}"
    boot_tar="\${${key}_BOOT_TAR}"

    boot_url=$URL/packages/$boot_os/bootstrap
    pgp_url=$URL/pgp

    cd /tmp

    # Download the pkgsrc kit to the current directory.
    eval curl -O $boot_url/$boot_tar

    # # Verify the SHA1 checksum.
    verify_checksum || true

    # # Verify PGP signature.  This step is optional, and requires gpg.
    verify_signature || true

    # Install bootstrap kit
    eval tar -zxpf $boot_tar -C /
    eval /bin/rm -f $boot_tar
}

verify_checksum() {
    if which shasum >/dev/null 2>&1; then
	create_tmpfile
	eval printf "%s\n" "$boot_sha  $boot_tar" >$tmpfile
	shasum -c $tmpfile
    fi
}

verify_signature() {
    if which gpg >/dev/null 2>&1; then
	eval curl -O $boot_url/$boot_tar.asc
	eval curl -sS $pgp_url/$boot_pgp.asc | gpg --import
	eval gpg --verify $boot_tar{.asc,}
	eval /bin/rm -f $boot_tar.asc
    fi
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/get-os-release.sh" -X)

install_pkgsrc
