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

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

change_owner() {
    assert [ $# -ge 1 ]

    if [ "$(id -un)" != "$APP_UID"  -o "$(id -gn)" != "$APP_GID" ]; then
	check_permissions "$@"

	if [ $dryrun = false -a $(id -u) -eq 0 ]; then
	    printf "Changing ownership of directory %s\n" "$@"
	    chown -R $APP_UID:$APP_GID "$@"
	fi
    fi
}

create_dirs() {
    assert [ $# -ge 1 ]
    check_permissions "$@"

    if [ $dryrun = false ]; then
	printf "Creating directory %s\n" "$@"
	mkdir -p "$@"
    fi
}

create_symlinks() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    source=$1
    shift

    for target_dir in "$@"; do
	create_symlink $source $UWSGI_ETCDIR/$target_dir/$APP_NAME.ini
    done
}

create_uwsgi_ini() {
    assert [ $# -ge 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" ]
    target=$1
    source=$2
    shift 2
    check_permissions $target

    if [ $dryrun = false ]; then
	printf "Generating configuration file %s\n" "$target"
	mkdir -p "$(dirname $target)"
	generate_sed_program "$@" >$tmpfile
	sed -f $tmpfile $source >$target
    fi
}

generate_sed_program() {
    assert [ $# -ge 1 ]

    for var; do
	eval value=\$$var
	pattern="\(.*\) = \(.*\)\$($var)\(.*\)"
	replace="\\1 = \\2$value\\3"
	printf 's|^#<%s>$|%s|g\n' "$pattern" "$replace"
	printf 's|^%s$|%s|g\n' "$pattern" "$replace"
    done
}

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

install_flask_app() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a -n "$3" ]
    mode=$1
    source_dir=$2
    target_dir=$3
    check_permissions $target_dir

    for source in $(find $source_dir -type f -name '*.py' -print | sort); do
	case $source in
	    (*/tests/*)
		: # Omit tests folder
		;;
	    (*/test_*.py)
		: # Omit test modules
		;;
	    (*)
		install_file $mode $source $target_dir/$source
		;;
	esac
    done
}

install_virtualenv() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    source_dir="$1"
    target_dir="$2"
    check_permissions "$target_dir"

    if [ $dryrun = false ]; then
	assert [ -r "$source_dir" ]
	printf "Installing files in %s\n" "$target_dir"
	mkdir -p $target_dir
	rsync -a "$source_dir"/* $target_dir
    fi
}

install_service() {
    create_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR
    install_file 600 .env $APP_DIR/.env
    install_flask_app 644 app $APP_DIR
    install_virtualenv $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
    change_owner $APP_DIR $APP_VARDIR
    create_uwsgi_ini $APP_CONFIG app.ini $UWSGI_VARS
    create_symlinks $APP_CONFIG $UWSGI_APPDIRS
}

start_service() {
    if signal_service HUP; then
	restart_service=false
	signal_received=true
    else
	case "$kernel_name" in
	    (Linux)
		case "$ID" in
		    (debian|ubuntu)
			restart_service=true
			;;
		    (*)
			restart_service=false
			;;
		esac
		;;
	    (*)
		restart_service=false
		;;
	esac

	/bin/rm -f $APP_PIDFILE
	signal_received=false
    fi

    if [ $restart_service = true ]; then
	service uwsgi restart
	wait_for_service
    elif [ $signal_received = false ]; then
	printf "Waiting for service %s to restart automatically\n" "$APP_NAME"
	sleep $KILL_INTERVAL
    fi
}

script_dir=$(get_path "$(dirname "$0")")

source_dir=$script_dir/..

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
cd "$source_dir"
tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM
venv_filename=$VENV_FILENAME-$APP_NAME

if [ "$(id -u)" -eq 0 ]; then
    sh="su $SUDO_USER"
else
    sh="sh -eu"
fi

for dryrun in true false; do
    "$script_dir/install-uwsgi.sh" $dryrun

    if [ $dryrun = false ]; then
	if ! $sh $script_dir/create-virtualenv.sh $venv_filename; then
	    abort "%s: Unable to create virtual environment\n" "$0"
	fi
    fi

    remove_database
    install_service
done

start_service

if [ -e $APP_PIDFILE ]; then
    tail_log_file
    printf "Service %s installed and started successfully\n" "$APP_NAME"
else
    printf "Service %s installed successfully\n" "$APP_NAME"
fi
