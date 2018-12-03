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

APP_PIPFILES="Pipfile Pipfile.lock requirements.txt"
APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_NAME APP_PIDFILE \
APP_PORT APP_RUNDIR APP_SOCKET APP_UID APP_VARDIR"

abort() {
    printf "$@" >&2
    exit 1
}

enable_app() {
    if [ $# -gt 0 ]; then
	generate_ini $SOURCE_DIR/app.ini | sh | sudo sh -c "cat >$1"
	source=$1
	shift

	for dest in "$@"; do
	    sudo ln -sf $source $dest
	done
    fi
}

generate_ini() {
    printf "%s" sed

    for var in $APP_VARS; do
	eval value="\$$var"
	printf -- " -e 's|\$(%s)|%s|g'" "$var" "$value"
    done

    printf " %s\n" "$@"
}

install_app() {
    (cd "$SOURCE_DIR"

     # Install application environment file
     sudo install -D .env "$APP_DIR"

     # Install application code files
     for source in $(find app -type f -name '*.py' -print | sort); do
	 case "$source" in
	     (*/test_*.py)
		 ;;
	     (*)
		 dest="$APP_DIR/$source"
		 printf "Copying %s to %s\n" "$source" "$dest"
		 sudo install -D -m 644 "$source" "$dest"
		 ;;
	 esac
     done

     # Make application the owner of the app and data directories
     if [ "$APP_GID" != root -o "$APP_UID" != root ]; then
	 sudo chown -R $APP_UID:$APP_GID $APP_DIR $APP_VARDIR
     fi)
}

install_venv() {
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export PIPENV_VENV_IN_PROJECT=true

    sudo -H pip3 install pipenv

    if pipenv >/dev/null; then
	sudo mkdir -p $APP_DIR/.venv

	(cd $SOURCE_DIR && sudo /bin/cp $APP_PIPFILES $APP_DIR)
	(cd $APP_DIR

	 if sudo -H pipenv sync; then
	     venv="$(sudo -H pipenv --venv)"

	     if [ -n "$venv" -a $venv != $APP_DIR/.venv ]; then
		 sudo sh -c "/bin/cp -rf $venv/* $APP_DIR/.venv"
	     fi
	 else
	     exit $?
	 fi)
    fi
}

# Set script directory
SCRIPT_DIR="$(dirname $0)"

# Set application parameters
. $SCRIPT_DIR/configure-app.sh

# Install uWSGI with Python 3 plugin
packages=$($SCRIPT_DIR/get-uwsgi-packages.sh)

if [ -n "$packages" ]; then
    install-packages $packages
fi

# Set source directory
SOURCE_DIR="$(readlink -f "$SCRIPT_DIR/..")"

# Create application directories
sudo mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR

# Install virtual environment
if install_venv; then

    # Install application
    install_app

    # Enable application
    enable_app $APP_CONFIG $UWSGI_CONF_FILES

    # Restart application
    signal_app HUP

    # Tail the log file
    tail_logfile
fi
