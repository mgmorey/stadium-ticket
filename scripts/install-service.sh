#!/bin/sh -eu

# install-service.sh: install application as a uWSGI service
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
	printf "Creating directory %s\n" $(printf "%s\n" "$@" | sort -u)
	mkdir -p "$@"
    fi
}

create_service_virtualenv() {
    if ! run_unpriv '"$script_dir/create-virtualenv.sh"' "$@"; then
	abort "%s: Unable to create virtual environment\n" "$0"
    fi
}

generate_sed_program() (
    assert [ $# -ge 1 ]

    for var; do
	eval value=\${$var-}

	case $var in
	    (APP_PLUGIN)
		if [ -n "$value" ]; then
		    pattern="\(plugin\) = python[0-9]*"
		    replace="\\1 = $value"
		    printf 's|^%s$|%s|g\n' "$pattern" "$replace"
		else
		    printf '/^plugin = [a-z0-9]*$/d\n'
		fi
		;;
	    (*)
		pattern="\(.*\) = \(.*\)\$($var)\(.*\)"
		replace="\\1 = \\2$value\\3"
		printf 's|^#<%s>$|%s|g\n' "$pattern" "$replace"
		printf 's|^%s$|%s|g\n' "$pattern" "$replace"
		;;
	esac
    done
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

get_setpriv_command() (
    assert [ -n "$1" ]
    username=$1
    shift

    case "$kernel_name" in
	(Linux)
	    options="--clear-groups"
	    regid="--regid $(id -g $username)"
	    reuid="--reuid $(id -u $username)"
	    setpriv="setpriv $reuid $regid"
	    version="$(setpriv --version 2>/dev/null)"

	    case "${version##* }" in
		(2.3[012].*)
		    options="--init-groups"
		    ;;
		(2.[12][0-9].*)
		    :
		    ;;
		(2.[0-9].*)
		    :
		    ;;
		([01].*)
		    :
		    ;;
		('')
		    ;;
		(*)
		    options="--init-groups --reset-env"
		    ;;
	    esac

	    printf "$setpriv %s %s\n" "$options" "$*"
	    return 0
	    ;;
	(*)
	    return 1
	    ;;
    esac
)

initialize_database() (
    cd $source_dir
    run_unpriv "'$script_dir/run.sh'" python3 -m app init-db
)

install_app_files() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" -a -n "$2" -a -d "$2" -a -n "$3" ]

    for source in $(find $2 -type f ! -name '*.pyc' -print | sort); do
	install_file $1 $source $3/$source
    done
)

install_service() {
    cd "$source_dir"

    for dryrun in true false; do
	if [ $UWSGI_IS_SOURCE_ONLY = true ]; then
	    install_uwsgi_from_source $UWSGI_BINARY_NAME $UWSGI_PLUGIN_NAME
	else
	    install_uwsgi_from_package
	fi

	if [ $dryrun = false ]; then
	    configure_system_defaults
	    validate_parameters_preinstallation
	    create_service_virtualenv $VENV_FILENAME-$APP_NAME
	fi

	create_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR $APP_LOGDIR $APP_RUNDIR

	if [ -r .env ]; then
	    install_file 600 .env $APP_DIR/.env
	fi

	install_app_files 644 app $APP_DIR
	install_virtualenv $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
	generate_service_ini $APP_CONFIG app.ini "$APP_VARS"
	change_owner $APP_ETCDIR $APP_DIR $APP_VARDIR
    done

    validate_parameters_postinstallation
}

install_uwsgi_from_package() (
    if [ $dryrun = true ]; then
	return 0
    fi

    is_installed_package=true
    packages=$("$script_dir/get-uwsgi-packages.sh")

    for package in $packages; do
	if ! is_installed $package; then
	    is_installed_package=false
	    break
	fi
    done

    if [ $is_installed_package = false ]; then
	"$script_dir/install-packages.sh" $packages
    fi
)

install_uwsgi_from_source() (
    dir=$(get_home_directory ${SUDO_USER-$USER})
    cd $dir/git/uwsgi

    for binary; do
	case $binary in
	    (*_plugin.so)
		install_file 755 $binary $UWSGI_PLUGIN_DIR/$binary
		;;
	    (uwsgi)
		install_file 755 $binary $UWSGI_BINARY_DIR/$binary
		;;
	esac
    done
)

install_virtualenv() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]

    if [ $dryrun = true ]; then
	check_permissions "$2"
    else
	assert [ -r "$1" ]
	printf "Installing virtual environment in %s\n" "$2"
	mkdir -p $2
	rsync -a $1/* $2
    fi
}

is_installed() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case "$kernel_name" in
	(Linux)
	    case "$ID" in
		(debian|ubuntu)
		    status=$(dpkg-query -Wf '${Status}\n' $1 2>/dev/null)
		    test "$status" = "install ok installed"
		    ;;
		(opensuse-*|fedora|redhat|centos)
		    rpm --query $1 >/dev/null 2>&1
		    ;;
		(*)
		    abort_not_supported Distro
		    ;;
	    esac
	    ;;
	(Darwin)
	    brew list 2>/dev/null | grep -E '^'"$1"'$' >/dev/null
	    ;;
	(FreeBSD)
	    pkg query %n "$1" >/dev/null 2>&1
	    ;;
	(*)
	    false
	    ;;
    esac
)

print_status() {
    case "$1" in
	(running)
	    print_service_processes 0
	    printf "Service %s installed and started successfully\n" "$APP_NAME"
	    printf "Service %s started in %d seconds\n" "$APP_NAME" "$total_elapsed"
	    ;;
	(stopped)
	    printf "Service %s installed successfully\n" "$APP_NAME"
	    ;;
	(*)
	    printf "Service %s is %s\n" "$APP_NAME" "$1" >&2
	    ;;
    esac
}

restart_service() {
    signal_received=false

    if ! is_service_running; then
	elapsed=0
    elif signal_process $WAIT_SIGNAL HUP; then
	signal_received=true
    fi

    total_elapsed=$elapsed
    printf "Waiting for service %s to start\n" "$APP_NAME"

    if [ $signal_received = true ]; then
	elapsed=$(wait_for_timeout $((WAIT_DEFAULT - total_elapsed)))
	total_elapsed=$((total_elapsed + elapsed))
    fi
}

run_unpriv() (
    assert [ $# -ge 1 ]

    if [ -n "${SUDO_USER-}" ] && [ "$(id -u)" -eq 0 ]; then
	setpriv=$(get_setpriv_command $SUDO_USER || true)
	eval ${setpriv:-/usr/bin/su -l $SUDO_USER} "$@"
    else
	eval "$@"
    fi
)

if [ $# -gt 0 ]; then
    abort "%s: Too many arguments\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$script_dir/..

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"
. "$script_dir/user-functions.sh"

configure_system
install_service
initialize_database
restart_service

status=$(get_service_status)
print_status $status

case $status in
    (running|stopped)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
