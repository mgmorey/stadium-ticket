#!/bin/sh -eu

APP_NAME=stadium-ticket
APP_PORT=5000

abort() {
    printf "$@" >&2
    exit 1
}

configure_app() {
    if [ $# -gt 0 ]; then
	generate_ini $SOURCE_DIR/app.ini | sh | sudo sh -c "cat >$1"

	if [ $# -gt 1 ]; then
	    sudo ln -sf $1 $2
	fi
    fi
}

generate_ini() {
    printf "%s" sed

    for var in APP_DIR APP_GID APP_NAME APP_PORT APP_UID APP_RUNDIR; do
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
     sudo chown -R $APP_UID:$APP_GID $APP_DIR $APP_VARDIR)
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

restart_app() {
    # Send restart signal to app
    if [ -r $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)

	if [ -n "$pid" ]; then
	    sudo kill -s HUP $pid
	fi
    fi
}

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
APP_ETCDIR=/etc/uwsgi
APP_RUNDIR=/opt/var/$APP_NAME
APP_VARDIR=/opt/var/$APP_NAME

# Set distro-specific parameters
distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		APP_GID=www-data
		APP_UID=www-data

		APP_CONFIG_AVAIL=$APP_ETCDIR/apps-available/$APP_NAME.ini
		APP_CONFIG_ENABLED=$APP_ETCDIR/apps-enabled/$APP_NAME.ini
		APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME

		APP_CONFIG_FILES="$APP_CONFIG_AVAIL $APP_CONFIG_ENABLED"
		APP_PIDFILE=$APP_RUNDIR/pid
		APP_SOCKET=$APP_RUNDIR/socket
		;;
	    (opensuse-*)
		APP_GID=nogroup
		APP_UID=nobody

		APP_CONFIG=$APP_ETCDIR/vassals/$APP_NAME.ini

		APP_CONFIG_FILES="$APP_CONFIG"
		APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
		APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac

# Set application filenames using directory variables
APP_PIPFILES="Pipfile Pipfile.lock requirements.txt"

# Set script and source directories
SCRIPT_DIR="$(dirname $0)"
SOURCE_DIR="$(readlink -f "$SCRIPT_DIR/..")"

# Install uWSGI with Python 3 plugin
packages=$($SCRIPT_DIR/get-uwsgi-packages.sh)

if [ -n "$packages" ]; then
    install-packages $packages
fi

# Create application directories
sudo mkdir -p $APP_DIR $APP_RUNDIR $APP_VARDIR

# Install virtual environment
if install_venv; then

    # Install application
    install_app

    # Configure application
    configure_app $APP_CONFIG_FILES

    # Restart application
    restart_app

fi
