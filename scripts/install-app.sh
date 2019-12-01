#!/bin/sh -eu

# install-app.sh: install application as a uWSGI service
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

CATEGORIES="devel sqlite uwsgi"

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

build_uwsgi_from_source() {
    if ! run_unpriv "$script_dir/build-uwsgi.sh" "$@"; then
	abort "%s: Unable to build uWSGI from source\n" "$0"
    fi
}

change_owner() (
    assert [ $# -ge 1 ]
    dirs=$(printf "%s\n" "$@" | sort -u)

    if [ "$(id -u)" -gt 0 ]; then
	return 0
    elif [ "$(id -un)" = "$APP_UID" -a "$(id -gn)" = "$APP_GID" ]; then
	return 0
    fi

    if [ $dryrun = true ]; then
	check_permissions $dirs
    else
	printf "Changing ownership of directory %s\n" $dirs
	chown -R $APP_UID:$APP_GID $dirs
    fi
)

create_dirs() (
    assert [ $# -ge 1 ]
    dirs=$(printf "%s\n" "$@" | sort -u)

    if [ $dryrun = true ]; then
	check_permissions $dirs
    else
	printf "Creating directory %s\n" $dirs
	mkdir -p $dirs
    fi
)

generate_sed_program() (
    assert [ $# -ge 1 ]

    for var; do
	eval value=\${$var-}

	case "$var" in
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
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    if [ $dryrun = false ]; then
	create_tmpfile
	sedfile=$tmpfile
	generate_sed_program $2 >$sedfile
	create_tmpfile
	inifile=$tmpfile
	sed -f $sedfile app.ini >$inifile
    else
	inifile=
    fi

    install_file 644 "$inifile" $1
}

get_packages_in() {
    for category; do
	"$script_dir/get-$category-packages.sh"
    done
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

install_app_files() (
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ -d $2 ]

    for source in $(find $2 -type f ! -name '*.pyc' -print | sort); do
	install_file $1 $source $3/$source
    done
)

install_dependencies() {
    if ! "$script_dir/install-dependencies.sh"; then
	abort "%s: Unable to install dependencies\n" "$0"
    fi
}

install_app() {
    if [ "$(is_uwsgi_packaged)" = false ]; then
	configure_defaults
    fi

    if [ -n "${source_dir-}" ]; then
	cd "$source_dir"
    fi

    for dryrun in true false; do
	if [ "$(is_uwsgi_packaged)" = false ]; then
	    configure_defaults
	    install_uwsgi_from_source $UWSGI_BINARY_NAME $UWSGI_PLUGIN_NAME
	else
	    install_uwsgi_from_package
	fi

	if [ $dryrun = false ]; then
	    if [ "$(is_uwsgi_packaged)" = true ]; then
		configure_defaults
	    fi

	    validate_parameters_preinstallation
	fi

	if [ -r .env ]; then
	    install_file 600 .env $APP_DIR/.env
	fi

	install_app_files 644 app $APP_DIR
	install_virtualenv $APP_DIR/$VENV_FILENAME
	generate_service_ini $APP_CONFIG "$APP_VARS"
	create_dirs $APP_VARDIR $APP_LOGDIR $APP_RUNDIR
	change_owner $APP_ETCDIR $APP_DIR $APP_VARDIR
    done

    validate_parameters_postinstallation
}

install_uwsgi_from_package() (
    if [ $dryrun = true ]; then
	return 0
    fi

    case "$UWSGI_ORIGIN" in
	(distro|pkgsrc)
	    packages=$(get_packages_in $CATEGORIES | sort -u)

	    if [ -n "$packages" ]; then
		"$script_dir/install-packages.sh" $packages
	    fi
	    ;;
	(pypi)
	    install_via_pip "$(get_pip_command)" uwsgi
	    ;;
    esac
)

install_uwsgi_from_source() (
    if [ $dryrun = false ]; then
	install_dependencies
	build_uwsgi_from_source $SYSTEM_PYTHON $SYSTEM_PYTHON_VERSION
	home_dir="$(get_home_directory $(get_user_name))"

	if ! cd "$home_dir/git/$UWSGI_BRANCH"; then
	    return 1
	fi
    fi

    for file; do
	case $file in
	    (*_plugin.so)
		install_file 755 $file $UWSGI_PLUGIN_DIR/$file
		;;
	    (uwsgi)
		install_file 755 $file $UWSGI_BINARY_DIR/$file
		;;
	esac
    done
)

install_virtualenv() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $dryrun = true ]; then
	check_permissions_single "$1"
    else
	printf "Installing virtual environment in %s\n" "$1"
	venv_force_sync=true
	venv_requirements=requirements.txt
	[ -n "${UWSGI_CC-}" ] && export CC="$UWSGI_CC"
	[ -n "${UWSGI_CFLAGS-}" ] && export CFLAGS="$UWSGI_CFLAGS"
	refresh_via_pip $1 $SYSTEM_PYTHON
    fi
)

parse_arguments() {
    while getopts hv: opt; do
	case $opt in
	    (h)
		usage
		exit 0
		;;
	    (v)
		venv_utilities=$OPTARG
		;;
	    (\?)
		printf "%s\n" "" >&2
		usage
		exit 2
		;;
	esac
    done

    shift $(($OPTIND - 1))
}

print_status() {
    case "$1" in
	(running)
	    print_app_processes 1
	    printf "Service %s installed and started successfully\n" "$APP_NAME"
	    print_elapsed_time started
	    ;;
	(stopped)
	    printf "Service %s installed successfully\n" "$APP_NAME"
	    ;;
	(*)
	    printf "Service %s is %s\n" "$APP_NAME" "$1" >&2
	    ;;
    esac
}

usage() {
    if [ $# -gt 0 ]; then
	printf "$@" >&2
	printf "%s\n" "" >&2
    fi

    cat <<-EOF >&2
	Usage: $0: [-v <VENV-UTILITIES>]
	       $0: -h
	EOF
}

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$(pwd)

until [ "$source_dir" = / -o -r "$source_dir/app.ini" ]; do
    source_dir="$(dirname $source_dir)"
done

if [ "$source_dir" = / ]; then
    unset source_dir
fi

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

parse_arguments "$@"
configure_baseline
install_app
signal_app_restart

status=$(get_app_status)
print_status $status

case $status in
    (running|stopped)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
