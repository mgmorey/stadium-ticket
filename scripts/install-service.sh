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

SLEEP_PERIOD=10

WAIT_INITIAL=2
WAIT_TIMEOUT=30

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

create_virtualenv() {
    if ! run_unprivileged '"$script_dir/create-virtualenv.sh"' $1; then
	abort "%s: Unable to create virtual environment\n" "$0"
    fi
}

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
}

run_python_unprivileged() (
    assert [ $# -ge 1 ]

    if [ "$(id -u)" -eq 0 ]; then
	dir=$APP_DIR
	python=$VENV_FILENAME/bin/python3
	sh="setpriv --clear-groups --egid $APP_GID --euid $APP_UID"
    else
	dir=$source_dir
	python=python3
	sh='"$script_dir/run.sh"'
    fi

    cd "$dir"
    eval $sh $python "$@"
)

restart_service() {
	case "$kernel_name" in
	    (Linux)
		service uwsgi restart
		;;
	    (Darwin)
		control_launch_agent load
		control_launch_agent start
		;;
	esac
}

start_service() (
    if signal_service HUP; then
	signal_received=true
    else
	signal_received=false
    fi

    if [ $signal_received = true ]; then
	case "$kernel_name" in
	    (Linux)
		case "$ID" in
		    (debian|ubuntu)
			restart_pending=false
			;;
		    (opensuse-*)
			restart_pending=false
			;;
		esac
		;;
	    (Darwin)
		restart_pending=false
		;;
	esac
    else
	case "$kernel_name" in
	    (Linux)
		case "$ID" in
		    (debian|ubuntu)
			restart_pending=true
			;;
		    (opensuse-*)
			restart_pending=false
			;;
		esac
		;;
	    (Darwin)
		restart_pending=true
		;;
	esac
    fi

    if [ $restart_pending = true ]; then
	restart_service
    fi

    printf "Waiting for service %s to start\n" "$APP_NAME"

    if [ $restart_pending = true ]; then
	wait_for_service $APP_PIDFILE $WAIT_INITIAL $WAIT_TIMEOUT
    elif [ $signal_received = false ]; then
	sleep $SLEEP_PERIOD
    fi
)

wait_for_service() {
    sleep $2
    i=0

    while [ ! -e $1 -a $i -lt $3 ]; do
	sleep 1
	i=$((i + 1))
    done

    if [ $i -ge $3 ]; then
	printf "Service failed to start within %s seconds\n" $1 >&2
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

for dryrun in true false; do
    "$script_dir/install-uwsgi.sh" $dryrun

    if [ $dryrun = false ]; then
	create_virtualenv $venv_filename
    fi

    remove_database
    install_service
done

start_service
run_python_unprivileged -m app init-db

if [ -e $APP_PIDFILE ]; then
    tail_file $APP_LOGFILE
    printf "Service %s installed and started successfully\n" "$APP_NAME"
else
    printf "Service %s installed successfully\n" "$APP_NAME"
fi
