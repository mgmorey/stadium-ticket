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

build_uwsgi_binary() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ -x $1 ]; then
	return 0
    fi

    case $1 in
	(python3*)
	    $python uwsgiconfig.py --plugin plugins/python core ${1%_*}
	    ;;
	(uwsgi)
	    $python uwsgiconfig.py --build core
    esac
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

create_service_virtualenv() {
    if ! shell '"$script_dir/create-service-venv.sh"' "$@"; then
	abort "%s: Unable to create virtual environment\n" "$0"
    fi
}

create_symlink() {
    assert [ $# -eq 2 ]
    assert [ -n "$2" ]

    if [ $dryrun = true ]; then
	check_permissions "$2"
    else
	assert [ -n "$1" ]
	assert [ -r $1 ]

	if [ $1 != $2 -a ! -e $2 ]; then
	    printf "Creating link %s\n" "$2"
	    /bin/ln -s $1 $2
	fi
    fi
}

create_symlinks() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    file=$1
    shift

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	return 0
    fi

    for dir in "$@"; do
	create_symlink $file $UWSGI_ETCDIR/$dir/$APP_NAME.ini
    done
)

enable_and_start_uwsgi() {
    case "$kernel_name" in
	(Linux)
	    systemctl enable uwsgi
	    systemctl start uwsgi
	    ;;
    esac
}

fetch_uwsgi_source() {
    if [ ! -d $HOME/git/uwsgi ]; then
	cd && mkdir -p git && cd git
	git clone https://github.com/unbit/uwsgi.git
    fi
}

generate_launch_agent_plist() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $dryrun = false ]; then
	create_tmpfile
	xmlfile=$tmpfile
	cat <<-EOF >$xmlfile
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	  <dict>
	    <key>Label</key>
	    <string>local.$APP_NAME</string>
	    <key>RunAtLoad</key>
	    <true/>
	    <key>KeepAlive</key>
	    <true/>
	    <key>ProgramArguments</key>
	    <array>
	        <string>$UWSGI_BINARY_DIR/uwsgi</string>
	        <string>--plugin-dir</string>
	        <string>$UWSGI_PLUGIN_DIR</string>
	        <string>--ini</string>
	        <string>$APP_CONFIG</string>
	    </array>
	    <key>WorkingDirectory</key>
	    <string>$APP_VARDIR</string>
	  </dict>
	</plist>
	EOF
    else
	xmlfile=
    fi

    install_file 644 "$xmlfile" $1
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

get_setpriv_command() (
    assert [ -n "$1" ]
    rgid="$(id -g $1)"
    ruid="$(id -u $1)"
    setpriv_opts="--clear-groups --rgid $rgid --ruid $ruid"
    setpriv_version="$(setpriv --version 2>/dev/null)"
    shift

    case "${setpriv_version##* }" in
	(2.3[3456789].*|2.[456789]?.*|[3456789].*)
	    setpriv_opts="$setpriv_opts --reset-env"
	    ;;
	(2.3[12].*)
	    :
	    ;;
	(2.23.*)
	    :
	    ;;
	(*)
	    return 1
	    ;;
    esac

    printf "setpriv %s %s\n" "$setpriv_opts" "$*"
    return 0
)

install_file() {
    assert [ $# -eq 3 ]
    assert [ -n "$3" ]

    if [ $dryrun = true ]; then
	check_permissions $3
    else
	assert [ -n "$1" ]
	assert [ -n "$2" ]
	assert [ -r $2 ]

	if is_tmpfile $2; then
	    printf "Generating file %s\n" "$3"
	else
	    printf "Installing file %s as %s\n" "$2" "$3"
	fi

	install -d -m 755 "$(dirname "$3")"
	install -C -m $1 $2 $3
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

    for source in $(find $2 -type f ! -name '*.pyc' -print | sort); do
	install_file $1 $source $3/$source
    done
)

install_service() {
    cd "$source_dir"

    # initialize the database before starting the service
    shell "'$script_dir/run.sh'" python3 -m app init-db

    for dryrun in true false; do
	case "$kernel_name" in
	    (Darwin)
		install_uwsgi_from_source $UWSGI_PLUGIN_NAME $UWSGI_BINARY_NAME
		;;
	    (*)
		install_uwsgi_from_package
		;;
	esac

	if [ $dryrun = false ]; then
	    create_service_virtualenv $VENV_FILENAME-$APP_NAME
	fi

	create_dirs $APP_DIR $APP_ETCDIR $APP_VARDIR
	install_file 600 .env $APP_DIR/.env
	install_flask_app 644 app $APP_DIR
	install_files $VENV_FILENAME-$APP_NAME $APP_DIR/$VENV_FILENAME
	generate_service_ini $APP_CONFIG app.ini "$UWSGI_VARS"
	change_owner $APP_ETCDIR $APP_DIR $APP_VARDIR
	create_symlinks $APP_CONFIG $UWSGI_APPDIRS
    done
}

install_uwsgi_binary() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    case $1 in
	(*_plugin.so)
	    install_file 755 $1 $UWSGI_PLUGIN_DIR/$1
	    ;;
	(uwsgi)
	    install_file 755 $1 $UWSGI_BINARY_DIR/$1
	    ;;
    esac
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

    enable_and_start_uwsgi
)

install_uwsgi_from_source() (
    if [ $dryrun = false ]; then
	fetch_uwsgi_source
    fi

    if [ $dryrun = false ]; then
	cd $HOME/git/uwsgi
	python=$(find_system_python)

	for binary; do
	    build_uwsgi_binary $binary
	done
    fi

    for binary; do
	install_uwsgi_binary $binary
    done
)

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
	    abort_not_supported "Operating system"
	    ;;
    esac
)

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep $1 >/dev/null
}

restart_service() {
    if signal_service $WAIT_SIGNAL HUP; then
	signal_received=true
    else
	signal_received=false
    fi

    total_elapsed=$elapsed
    set_start_pending

    if [ $start_pending = true ]; then
	start_service
	total_elapsed=0
    fi

    if [ $start_pending = true -o $signal_received = false ]; then
	printf "Waiting for service %s to start\n" "$APP_NAME"
    fi

    if [ $start_pending = true ]; then
	wait_period=$((WAIT_RESTART - total_elapsed))
	elapsed=$(wait_for_service $APP_PIDFILE $wait_period)
    elif [ $signal_received = true ]; then
	elapsed=$(wait_for_timeout $((WAIT_DEFAULT - total_elapsed)))
    else
	elapsed=$(wait_for_timeout $((WAIT_DEFAULT - total_elapsed)))
    fi

    total_elapsed=$((total_elapsed + elapsed))

    if [ $total_elapsed -lt $WAIT_DEFAULT ]; then
	elapsed=$(wait_for_timeout $((WAIT_DEFAULT - total_elapsed)))
	total_elapsed=$((total_elapsed + elapsed))
    fi
}

set_start_pending() {
    if [ $signal_received = true ]; then
	case "$kernel_name" in
	    (*)
		start_pending=false
		;;
	esac
    else
	case "$kernel_name" in
	    (Linux)
		case "$ID" in
		    (debian|ubuntu)
			start_pending=true
			;;
		    (*)
			start_pending=false
			;;
		esac
		;;
	    (Darwin)
		start_pending=true
		;;
	    (*)
		start_pending=false
		;;
	esac
    fi
}

shell() (
    assert [ $# -ge 1 ]

    if [ "$(id -u)" -eq 0 -a -n "${SUDO_USER:-}" ]; then
	su=$(get_setpriv_command $SUDO_USER || true)

	if [ -z "$su" ]; then
	    su="/usr/bin/su -l $SUDO_USER"
	fi

	eval $su "$@"
    else
	eval "$@"
    fi
)

show_status() {
    if [ -e $APP_PIDFILE ]; then
	printf "Service started in %s seconds\n" "$total_elapsed"
	show_logs $APP_LOGFILE
	printf "Service %s installed and started successfully\n" "$APP_NAME"
    else
	printf "Service %s installed successfully\n" "$APP_NAME"
    fi
}

start_service() {
    case "$kernel_name" in
	(Linux)
	    systemctl restart uwsgi
	    ;;
	(Darwin)
	    control_launch_agent load generate_launch_agent_plist
	    control_launch_agent start
	    ;;
    esac
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
	printf "Service failed to start within %s seconds\n" $2 >&2
    fi

    printf "%s\n" "$i"
}

wait_for_timeout() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]

    if [ $1 -gt 0 ]; then
	sleep $1
	printf "%s\n" "$1"
    else
	printf "%s\n" 0
    fi
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
restart_service
show_status
