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

WAIT_DEFAULT=2
WAIT_RESTART=10

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

change_owner() {
    assert [ $# -ge 1 ]

    if [ "$(id -u)" -gt 0 ]; then
	return 0
    elif [ "$(id -un)" = "$APP_UID" -a "$(id -gn)" = "$APP_GID" ]; then
	return 0
    fi

    if [ $dryrun = true ]; then
	check_permissions "$@"
    else
	printf "Changing ownership of directory %s\n" "$@"
	chown -R $APP_UID:$APP_GID "$@"
    fi
}

create_dirs() {
    assert [ $# -ge 1 ]

    if [ $dryrun = true ]; then
	check_permissions "$@"
    else
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

create_service_virtualenv() {
    if ! shell '"$script_dir/check-home.sh"'; then
	abort "%s: Unable to create virtual environment\n" "$0"
    fi

    if ! shell '"$script_dir/create-service-venv.sh"' "$@"; then
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

    case "$kernel_name" in
	(FreeBSD)
	    printf '/^plugin = [a-z0-9]*$/d\n'
	    ;;
    esac
)

generate_service_ini() {
    assert [ $# -eq 3 ]
    assert [ -n "$2" -a -r "$2" -a -n "$3" ]

    if [ $dryrun = false ]; then
	create_tmpfile
	sedfile=$tmpfile
	generate_sed_program $3 >$sedfile
	create_tmpfile
	inifile=$tmpfile
	sed -f $sedfile $2 >$inifile
    else
	inifile=
    fi

    install_file 644 "$inifile" $1
}

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

get_status() {
    if [ -e $APP_PIDFILE ]; then
	printf "Service started in %s seconds\n" "$total_elapsed"
	show_logs $APP_LOGFILE
	printf "Service %s installed and started successfully\n" "$APP_NAME"
    else
	printf "Service %s installed successfully\n" "$APP_NAME"
    fi
}

install_files() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]

    if [ $dryrun = true ]; then
	check_permissions "$2"
    else
	assert [ -r "$1" ]
	printf "Installing files in directory %s\n" "$2"
	mkdir -p $2
	rsync -a $1/* $2
    fi
}

install_flask_app() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -d "$2" -a -n "$3" ]

    for source in $(find $2 -type f -print | sort); do
	install_file $1 $source $3/$source
    done
)

install_service() {
    cd "$source_dir"

    # initialize the database before starting the service
    shell "'$script_dir/run.sh'" python3 -m app init-db

    for dryrun in true false; do
	case "$kernel_name" in
	    (Linux)
		install_uwsgi
		;;
	    (Darwin)
		"$script_dir/install-uwsgi-from-source.sh" $dryrun
		;;
	    (FreeBSD)
		install_uwsgi
		;;
	esac

	if [ $dryrun = false ]; then
	    create_service_virtualenv $VENV_FILENAME-$APP_NAME
	fi

	install_service_files
    done
}

install_service_files() {
    create_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR
    install_file 600 .env $APP_DIR/.env
    install_flask_app 644 app $APP_DIR
    install_files $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
    generate_service_ini $APP_CONFIG app.ini "$UWSGI_VARS"
    change_owner $APP_ETCDIR $APP_DIR $APP_VARDIR
    create_symlinks $APP_CONFIG $UWSGI_APPDIRS
}

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

set_restart_pending() {
    if [ $signal_received = true ]; then
	case "$kernel_name" in
	    (*)
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
		    (*)
			restart_pending=false
			;;
		esac
		;;
	    (Darwin)
		restart_pending=true
		;;
	    (*)
		restart_pending=false
		;;
	esac
    fi
}

start_service() {
    if signal_service_restart; then
	signal_received=true
    else
	signal_received=false
    fi

    total_elapsed=$elapsed
    set_restart_pending

    if [ $restart_pending = true ]; then
	restart_service
	total_elapsed=0
    fi

    if [ $restart_pending = true -o $signal_received = false ]; then
	printf "Waiting for service %s to start\n" "$APP_NAME"
    fi

    if [ $restart_pending = true ]; then
	wait_period=$((WAIT_RESTART - total_elapsed))
	elapsed=$(wait_for_service $APP_PIDFILE $wait_period)
    elif [ $signal_received = true ]; then
	elapsed=$(wait_for_interval $((WAIT_DEFAULT - total_elapsed)))
    else
	elapsed=$(wait_for_interval $((WAIT_DEFAULT - total_elapsed)))
    fi

    total_elapsed=$((total_elapsed + elapsed))

    if [ $total_elapsed -lt $WAIT_DEFAULT ]; then
	elapsed=$(wait_for_interval $((WAIT_DEFAULT - total_elapsed)))
	total_elapsed=$((total_elapsed + elapsed))
    fi
}

wait_for_interval() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $1 -gt 0 ]; then
	sleep $1
	printf "%s\n" "$1"
    else
	printf "%s\n" 0
    fi
}

wait_for_service() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]
    i=0

    if [ $2 -gt 0 ]; then
	while [ ! -e $1 -a $i -lt $2 ]; do
	    sleep 1
	    i=$((i + 1))
	done
    fi

    if [ $i -ge $2 ]; then
	printf "Service failed to start within %s seconds\n" $3 >&2
    fi

    printf "%s\n" "$i"
}

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$script_dir/..

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
install_service
start_service
get_status
