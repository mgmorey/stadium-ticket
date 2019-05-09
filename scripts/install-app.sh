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

build_uwsgi_binary() {
    assert [ $# -eq 1 ]

    if [ -x $1 ]; then
	return
    fi

    find_system_python

    case $1 in
	(python3*)
	    $python uwsgiconfig.py --plugin plugins/python core ${1%_*}
	    ;;
	(uwsgi)
	    $python uwsgiconfig.py --build core
    esac
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

create_uwsgi_ini() {
    assert [ $# -gt 2 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" ]
    ini_file=$1
    shift
    check_permissions $ini_file

    if [ $dryrun = false ]; then
	printf "Generating configuration file %s\n" "$ini_file"
	mkdir -p "$(dirname $ini_file)"
	eval $(generate_commands "$@") >$ini_file
    fi
}

create_symlink() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    source=$1
    target=$2
    check_permissions "$target"

    if [ $dryrun = false ]; then
	assert [ -r "$source" ]

	if [ $source != $target ]; then
	    printf "Creating link %s\n" "$target"
	    /bin/ln -sf $source $target
	fi
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

generate_commands() {
    assert [ $# -gt 1 ]
    assert [ -n "$1" -a -r "$1" ]
    file=$1
    shift
    printf "%s" "sed"

    for var; do
	eval value=\$$var
	pattern="\(.*\) = \(.*\)\$($var)\(.*\)"
	replace="\\1 = \\2$value\\3"
	printf " -e 's;^#<%s>$;%s;g'" "$pattern" "$replace"
	printf " -e 's;^%s$;%s;g'" "$pattern" "$replace"
    done

    printf " %s\n" "$file"
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

install_file() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a -n "$3" ]
    mode=$1
    source=$2
    target=$3
    check_permissions $target

    if [ $dryrun = false ]; then
	printf "Installing file %s as %s\n" "$source" "$target"
	install -d -m 755 "$(dirname "$target")"
	install -C -m $mode $source $target
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

install_uwsgi() {
    case "$kernel_name" in
	(Darwin)
	    install_uwsgi_binaries $UWSGI_BINARY_NAME $UWSGI_PLUGIN_NAME
	    ;;
	(*)
	    if ! "$script_dir/is-installed-package.sh" $UWSGI_BINARY_NAME; then
		packages=$("$script_dir/get-uwsgi-packages.sh")
		"$script_dir/install-packages.sh" $packages
		start_uwsgi
	    fi
	    ;;
    esac
}

install_uwsgi_binaries() {
    (
	if [ ! -d $HOME/git/uwsgi ]; then
	    cd && mkdir -p git && cd git
	    git clone https://github.com/unbit/uwsgi.git
	fi

	cd $HOME/git/uwsgi

	for binary; do
	    build_uwsgi_binary $binary
	done

	for binary; do
	    install_uwsgi_binary $binary
	done
    )
}

install_uwsgi_binary() {
    case $binary in
	(*_plugin.so)
	    if [ ! -x $UWSGI_PLUGIN_DIR/$1 ]; then
		install_file 755 $1 $UWSGI_PLUGIN_DIR/$1
	    fi
	    ;;
	(uwsgi)
	    if [ ! -x $UWSGI_BINARY_DIR/$1 ]; then
		install_file 755 $1 $UWSGI_BINARY_DIR/$1
	    fi

	    create_symlink $UWSGI_BINARY_DIR/$1 /usr/local/bin/$1
	    ;;
    esac
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

if [ "$(id -u)" -eq 0 ]; then
    sh="su $SUDO_USER"
else
    sh="sh -eu"
fi

cd "$source_dir"

tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM
venv_filename=$VENV_FILENAME-$APP_NAME

for dryrun in true false; do
    if [ $dryrun = false ]; then
	install_uwsgi

	if ! $sh "$script_dir/stage-virtualenv.sh" $venv_filename; then
	    abort "%s: Unable to stage virtual environment\n" "$0"
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
