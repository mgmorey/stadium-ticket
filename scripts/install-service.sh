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

WAIT_INITIAL_PERIOD=2
WAIT_POLLING_COUNT=20

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

create_symlinks() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    file=$1
    shift

    for dir in "$@"; do
	create_symlink $file $UWSGI_ETCDIR/$dir/$APP_NAME.ini
    done
)

generate_sed_program() (
    assert [ $# -ge 1 ]

    for var; do
	eval value=\$$var
	pattern="\(.*\) = \(.*\)\$($var)\(.*\)"
	replace="\\1 = \\2$value\\3"
	printf 's|^#<%s>$|%s|g\n' "$pattern" "$replace"
	printf 's|^%s$|%s|g\n' "$pattern" "$replace"
    done
)

generate_service_ini() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a "$3" ]
    check_permissions $1

    if [ $dryrun = false ]; then
	printf "Generating configuration file %s\n" "$1"
	mkdir -p "$(dirname $1)"
	generate_sed_program $3 >$tmpfile
	sed -f $tmpfile $2 >$1
    fi
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

install_flask_app() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a -n "$3" ]
    check_permissions $3

    for source in $(find $2 -type f -name '*.py' -print | sort); do
	case $source in
	    (*/tests/*)
		: # Omit tests folder
		;;
	    (*/test_*.py)
		: # Omit test modules
		;;
	    (*)
		install_file $1 $source $3/$source
		;;
	esac
    done
)

install_virtualenv() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]
    check_permissions "$2"

    if [ $dryrun = false ]; then
	assert [ -r "$1" ]
	printf "Installing files in %s\n" "$2"
	mkdir -p $2
	rsync -a "$1"/* $2
    fi
}

install_service() {
    create_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR
    install_file 600 .env $APP_DIR/.env
    install_flask_app 644 app $APP_DIR
    install_virtualenv $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
    change_owner $APP_DIR $APP_VARDIR
    generate_service_ini $APP_CONFIG app.ini "$UWSGI_VARS"
    create_symlinks $APP_CONFIG $UWSGI_APPDIRS

    case "$kernel_name" in
	(Darwin)
	    control_launch_agent load
	    ;;
    esac
}

start_service() (
    restart_service=false

    if signal_service HUP; then
	signal_received=true
    else
	signal_received=false
    fi

    if [ $signal_received = false ]; then
	/bin/rm -f $APP_PIDFILE
    fi

    # Initialize database by invoking app module
    $sh "$script_dir/run.sh" python3  -m app init-db

    if [ $signal_received = true ]; then
	case "$kernel_name" in
	    (Linux)
		case "$ID" in
		    (debian|ubuntu)
			restart_service=true
			;;
		esac

		if [ $restart_service = true ]; then
		    service uwsgi restart
		fi
		;;
	esac
    fi

    printf "Waiting for service %s to start\n" "$APP_NAME"

    if [ $restart_service = true ]; then
	wait_for_pidfile $APP_PIDFILE $WAIT_INITIAL_PERIOD $WAIT_POLLING_COUNT
    elif [ $signal_received = false ]; then
	sleep $KILL_INTERVAL
    fi
)

wait_for_pidfile() {
    sleep $2
    i=0

    while [ ! -e $1 -a $i -lt $3 ]; do
	sleep 1
	i=$((i + 1))
    done

    if [ $i -ge $3 ]; then
	printf "Timeout waiting for PID file %s\n" $1 >&2
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
	if ! $sh "$script_dir/create-virtualenv.sh" $venv_filename; then
	    abort "%s: Unable to create virtual environment\n" "$0"
	fi
    fi

    remove_database
    install_service
done

start_service

if [ -e $APP_PIDFILE ]; then
    tail_file $APP_LOGFILE
    printf "Service %s installed and started successfully\n" "$APP_NAME"
else
    printf "Service %s installed successfully\n" "$APP_NAME"
fi
