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

check_parent_dir_permissions() {
    for file in "$@"; do
	dir="$(dirname "$file")"
	check_permissions "$dir"
    done
}

check_permissions() {
    for file; do
	if [ ! -w "$file" ]; then
	    abort "%s: No write permission\n" "$file"
	fi
    done
}

enable_app() {
    if [ $# -gt 0 ]; then
	generate_ini "$source_dir/app.ini" | sh | cat >$1
	source=$1
	shift
    fi

    for dir; do
	dest=$UWSGI_ETCDIR/$dir/$APP_NAME.ini

	if [ -d $(dirname $dest) ]; then
	    printf "Linking %s to %s\n" $source $dest
	    ln -sf $source "$dest"
	fi
    done
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
    # Create application directories
    check_parent_dir_permissions $app_dirs
    mkdir -p $app_dirs

    # Install application environment file
    check_permissions "$APP_DIR" "$APP_DIR/.env"
    install -m 600 .env "$APP_DIR"

    # Install application code files
    for source in $(find app -type f -name '*.py' -print | sort); do
	case "$source" in
	    (*/test_*.py)
	    ;;
	    (*)
		dest="$APP_DIR/$source"
		dest_dir="$(dirname "$dest")"
		check_permissions "$dest_dir" "$dest"
		printf "Copying %s to %s\n" "$source" "$dest"
		install -d -m 755 "$dest_dir"
		install -C -m 644 "$source" "$dest"
		;;
	esac
    done

    # Make application the owner of the app and data directories
    if [ "$APP_GID" != root -o "$APP_UID" != root ]; then
	chown -R $APP_UID:$APP_GID $APP_DIR $APP_VARDIR
    fi
}

install_venv() {
    if [ -d $virtualenv ]; then
	printf "Copying %s to %s\n" $virtualenv "$APP_DIR/.venv"
	check_permissions "$APP_DIR" "$APP_DIR/.venv"
	mkdir -p "$APP_DIR/.venv"
	rsync -an $virtualenv/ $APP_DIR/.venv
	rsync -a $virtualenv/ $APP_DIR/.venv
    else
	abort "%s\n" "No virtual environment"
    fi
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

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

if [ "$(id -u)" -gt 0 ]; then
    sh=/bin/sh
elif [ -n "$SUDO_USER" ]; then
    sh="su - $SUDO_USER"
fi

$sh "$script_dir/stage-app.sh"

. "$script_dir/configure-app.sh"

app_dirs="$APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR"
virtualenv=.venv-$APP_NAME
cd "$source_dir"

install_app
install_venv
enable_app $APP_CONFIG $UWSGI_APPDIRS
signal_app HUP
tail_logfile
