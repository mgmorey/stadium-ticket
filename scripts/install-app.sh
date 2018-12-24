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

change_ownership() {
    if [ "$(id -un)" != "$APP_UID"  -o "$(id -gn)" != "$APP_GID" ]; then
	check_permissions "$@"

	if [ "$dryrun" = false ]; then
	    printf "Changing ownership of directory %s\n" "$@"
	    chown -R $APP_UID:$APP_GID "$@"
	fi
    fi

}

create_app_dirs() {
    check_permissions $app_dirs

    if [ "$dryrun" = false ]; then
	printf "Creating directory %s\n" $app_dirs
	mkdir -p $app_dirs
    fi
}

create_app_ini() {
    source="$1"
    target="$2"
    check_permissions "$target"

    if [ "$dryrun" = false ]; then
	if [ -f "$source" ]; then
	    printf "Generating file %s\n" "$target"
	    mkdir -p "$(dirname "$target")"
	    generate_ini "$source" | sh | cat >"$target"
	else
	    abort "%s: No such file\n" "$source"
	fi
    fi

}

enable_app() {
    if [ $# -gt 0 ]; then
	create_app_ini app.ini "$1"
	source=$1
	shift

	for name; do
	    target=$UWSGI_ETCDIR/$name/$APP_NAME.ini
	    check_permissions "$target"

	    if [ "$dryrun" = false ]; then
		printf "Linking file %s to %s\n" "$source" "$target"
		mkdir -p "$(dirname "$target")"
		/bin/ln -sf "$source" "$target"
	    fi
	done
    else
	abort "%s\n" "Invalid number of arguments"
    fi
}

generate_ini() {
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

    # Create application directories
    create_app_dirs

    # Install application environment file
    install_file "$@" 600 .env "$APP_DIR/.env"

    # Install application code files
    for source in $(find app -type f -name '*.py' -print | sort); do
	case "$source" in
	    (*/test_*.py)
	    ;;
	    (*)
		install_file 644 "$source" "$APP_DIR/$source"
		;;
	esac
    done

    install_venv "$virtualenv"
    change_ownership $APP_DIR $APP_VARDIR
    enable_app $APP_CONFIG $UWSGI_APPDIRS
}

install_file() {
    if [ $# -eq 3 ]; then
	mode="$1"
	source="$2"
	target="$3"
	check_permissions "$target"

	if [ "$dryrun" = false ]; then
	    if [ -f $source ]; then
		printf "Installing file %s as %s\n" "$source" "$target"
		install -d -m 755 "$(dirname "$target")"
		install -C -m "$mode" "$source" "$target"
	    else
		abort "%s: No such file\n" "$source"
	    fi
	fi
    else
	abort "%s\n" "Invalid number of arguments"
    fi
}

install_files() {
    if [ $# -gt 2 ] && [ "$1" = -t ]; then
	target="$2"
	shift 2
	check_permissions "$target"

	if [ "$dryrun" = false ]; then
	    printf "Installing files in %s\n" "$target"
	    mkdir -p "$target"
	    rsync -a "$@" "$target"
	fi
    else
	abort "%s\n" "Invalid number of arguments"
    fi
}

install_venv() {
    install_files -t "$APP_DIR/.venv" "$1"/*
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
    if [ "$(id -u)" -gt 0 ]; then
	sh=/bin/sh
    elif [ -n "$SUDO_USER" ]; then
	sh="su $SUDO_USER"
    fi

    $sh "$script_dir/stage-app.sh"
}

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

. "$script_dir/configure-app.sh"

app_dirs="$APP_DIR $APP_ETCDIR $APP_VARDIR"
virtualenv=.venv-$APP_NAME
cd "$source_dir"

install_app -n
stage_app
install_app
signal_app HUP
tail_log
