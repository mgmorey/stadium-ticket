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

change_ownership() {
    assert [ $# -ge 1 ]

    if [ "$(id -un)" != "$APP_UID"  -o "$(id -gn)" != "$APP_GID" ]; then
	check_permissions "$@"

	if [ $dryrun = false -a $(id -u) -eq 0 ]; then
	    printf "Changing ownership of directory %s\n" "$@"
	    chown -R $APP_UID:$APP_GID "$@"
	fi
    fi
}

create_app_dirs() {
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
    file=$1
    shift

    for dir; do
	create_symlink $file $UWSGI_ETCDIR/$dir/$APP_NAME.ini
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

install_app_and_config() {
    create_app_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR
    install_source_files 644 app $APP_DIR
    install_file 600 .env $APP_DIR/.env
    install_dir $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
    change_ownership $APP_DIR $APP_VARDIR
    create_uwsgi_ini $APP_CONFIG app.ini $UWSGI_VARS
    create_symlinks $APP_CONFIG $UWSGI_APPDIRS
}

install_dir() {
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

install_source_files() {
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

start_app() {
    if signal_app HUP; then
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

	signal_received=false
    fi

    if [ $restart_service = true ]; then
	start_service
    elif [ $signal_received = false ]; then
	printf "Waiting for app %s to restart automatically\n" "$APP_NAME"
	sleep $KILL_INTERVAL
    fi
}

start_service() {
    /bin/rm -f $APP_PIDFILE
    service uwsgi restart
    wait_for_service
}

start_uwsgi() {
    systemctl enable uwsgi
    systemctl start uwsgi
}

wait_for_service() {
    printf "%s\n" "Waiting for service and app to start"
    sleep $WAIT_INITIAL_PERIOD
    i=0

    while [ ! -e $APP_PIDFILE -a $i -lt $WAIT_POLLING_COUNT ]; do
	sleep 1
	i=$((i + 1))
    done

    if [ $i -ge $WAIT_POLLING_COUNT ]; then
	printf "%s\n" "App did not start in a timely fashion" >&2
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
	if ! "$script_dir/create-virtualenv.sh" $venv_filename; then
	    abort "%s: Unable to create virtual environment\n" "$0"
	fi
    fi

    remove_database
    install_app_and_config
done

start_app

if [ -e $APP_PIDFILE ]; then
    tail_log_file
    printf "App %s installed and started successfully\n" "$APP_NAME"
else
    printf "App %s installed successfully\n" "$APP_NAME"
fi
