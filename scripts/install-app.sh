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

APP_VARS="APP_DIR APP_GID APP_LOGFILE APP_NAME APP_PIDFILE APP_PORT \
APP_RUNDIR APP_UID APP_VARDIR"

create_venv() {
    (cd $source_dir
     venv=.venv-$APP_NAME

     if [ ! -d $venv ]; then
	 python3 -m venv $venv
     fi

     if [ -d $venv ]; then
	 . $venv/bin/activate
	 pip3 install --upgrade pip
	 pip3 install -r $source_dir/requirements.txt
	 printf "Copying %s to %s\n" $venv "$APP_DIR/.venv"
	 sudo mkdir -p "$APP_DIR/.venv"
	 sudo rsync -a $venv/ $APP_DIR/.venv
     else
	 abort "%s\n" "No available virtualenv"
     fi)
}

enable_app() {
    if [ $# -gt 0 ]; then
	generate_ini $source_dir/app.ini | sh | sudo sh -c "cat >$1"
	source=$1
	shift
    fi

    for dir in "$@"; do
	dest=$UWSGI_ETCDIR/$dir/$APP_NAME.ini

	if [ -d $(dirname $dest) ]; then
	    printf "Linking %s to %s\n" $source $dest
	    sudo ln -sf $source "$dest"
	fi
    done
}

generate_ini() {
    printf "%s" "sed -e 's|^#<\\(.*\\)>$|\\1|g'"

    for var in $APP_VARS; do
	eval value="\$$var"
	printf " %s" "-e 's|\$($var)|$value|g'"
    done

    printf " %s\n" "$*"
}

install_app() {
    (cd "$source_dir"

     # Create application directories
     sudo mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR

     # Install application environment file
     sudo install -m 600 .env "$APP_DIR"

     # Install application code files
     for source in $(find app -type f -name '*.py' -print | sort); do
	 case "$source" in
	     (*/test_*.py)
	     ;;
	     (*)
		 dest="$APP_DIR/$source"
		 printf "Copying %s to %s\n" "$source" "$dest"
		 sudo install -d -m 755 $(dirname "$dest")
		 sudo install -C -m 644 "$source" "$dest"
		 ;;
	 esac
     done

     # Make application the owner of the app and data directories
     if [ "$APP_GID" != root -o "$APP_UID" != root ]; then
	 sudo chown -R $APP_UID:$APP_GID $APP_DIR $APP_VARDIR
     fi)
}

export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# Set script and source directories
script_dir="$(dirname $0)"
source_dir="$(readlink -f "$script_dir/..")"

. $script_dir/configure-app.sh
create_venv
install_app
enable_app $APP_CONFIG $UWSGI_APPDIRS
signal_app HUP
tail_logfile
