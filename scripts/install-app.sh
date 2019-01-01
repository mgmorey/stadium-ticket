#!/bin/sh -eu

# install-app.sh: install uWSGI application
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

APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_NAME APP_PIDFILE APP_PORT \
APP_RUNDIR APP_UID APP_VARDIR"

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

change_ownership() {
    assert [ $# -ge 1 ]

    if [ "$(id -un)" != "$APP_UID"  -o "$(id -gn)" != "$APP_GID" ]; then
	check_permissions "$@"

	if [ "$dryrun" = false ]; then
	    printf "Changing ownership of directory %s\n" "$@"
	    chown -R $APP_UID:$APP_GID "$@"
	fi
    fi
}

create_app_dirs() {
    assert [ $# -ge 1 ]
    check_permissions "$@"

    if [ "$dryrun" = false ]; then
	printf "Creating directory %s\n" "$@"
	mkdir -p "$@"
    fi
}

create_app_ini() {
    assert [ $# -eq 2 ] && [ -n "$1" ] && [ -r "$1" ]
    source="$1"
    target="$2"
    check_permissions "$target"

    if [ "$dryrun" = false ]; then
	assert [ -r "$source" ]
	printf "Generating file %s\n" "$target"
	mkdir -p "$(dirname "$target")"
	generate_ini "$source" | sh | cat >"$target"
    fi
}

enable_app() {
    assert [ $# -ge 1 ] && [ -n "$1" ]
    create_app_ini app.ini "$1"
    source=$1
    shift

    for name; do
	target=$UWSGI_ETCDIR/$name/$APP_NAME.ini
	check_permissions "$target"

	if [ "$dryrun" = false ]; then
	    assert [ -r "$source" ]
	    printf "Creating link %s\n" "$target"
	    mkdir -p "$(dirname "$target")"
	    /bin/ln -sf "$source" "$target"
	fi
    done
}

generate_ini() {
    assert [ $# -eq 1 ] && [ -n "$1" ] && [ -r "$1" ]
    printf "%s" "sed -e 's|^#<\\(.*\\)>$|\\1|g'"

    for var in $APP_VARS; do
	eval value=\$$var
	printf " %s" "-e 's|\$($var)|$value|g'"
    done

    printf " %s\n" "$*"
}

install_app() {
    if [ $# -gt 0 ] && [ "$1" = -n ]; then
	dryrun=true
	shift
    else
	dryrun=false
    fi

    create_app_dirs "$APP_DIR" "$APP_ETCDIR" "$APP_VARDIR"
    install_source_files 644 app "$APP_DIR"
    install_file "$@" 600 .env "$APP_DIR/.env"
    install_dir "$virtualenv" "$APP_DIR/.venv"
    change_ownership "$APP_DIR" "$APP_VARDIR"
    enable_app "$APP_CONFIG" $UWSGI_APPDIRS
}

install_dir() {
    assert [ $# -eq 2 ] && [ -n "$1" ]
    source_dir="$1"
    target_dir="$2"
    check_permissions "$target_dir"

    if [ "$dryrun" = false ]; then
	assert [ -r "$source_dir" ]
	printf "Installing files in %s\n" "$target_dir"
	mkdir -p "$target_dir"
	rsync -a "$source_dir"/* "$target_dir"
    fi
}

install_file() {
    assert [ $# -eq 3 ] && [ -n "$1" ] && [ -n "$2" ] && [ -r "$2" ]
    mode="$1"
    source="$2"
    target="$3"
    check_permissions "$target"

    if [ "$dryrun" = false ]; then
	assert [ -r "$source" ]
	printf "Installing file %s as %s\n" "$source" "$target"
	install -d -m 755 "$(dirname "$target")"
	install -C -m "$mode" "$source" "$target"
    fi
}

install_source_files() {
    assert [ $# -eq 3 ] && [ -n "$1" ] && [ -n "$2" ] && [ -r "$2" ]
    mode="$1"
    source_dir="$2"
    target_dir="$3"
    check_permissions "$target_dir"

    for source in $(find "$source_dir" -type f -name '*.py' -print | sort); do
	assert [ -r "$source" ]

	case "$source" in
	    (*/tests/*)
		: # Omit tests folder
		;;
	    (*/test_*.py)
		: # Omit test modules
		;;
	    (*)
		install_file "$mode" "$source" "$target_dir/$source"
		;;
	esac
    done
}

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

stage_app() {
    if [ "$(id -u)" -eq 0 ]; then
	sh="su $SUDO_USER"
    else
	sh="sh -eu"
    fi

    $sh "$script_dir/stage-app.sh"
}

script_dir=$(realpath $(dirname $0))
source_dir="$script_dir/.."

. "$script_dir/configure-app.sh"

virtualenv=.venv-$APP_NAME
cd "$source_dir"

install_app -n
stage_app
install_app
signal_app HUP
tail_log
