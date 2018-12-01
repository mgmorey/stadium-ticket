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

    for var in APP_NAME APP_PORT APP_GID APP_UID APP_DIR; do
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
     sudo chown -R $APP_UID:$APP_GID $APP_DIR $VAR_DIR)
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
ETC_DIR=/etc/uwsgi
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

# Set distro-specific parameters
distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		APP_GID=www-data
		APP_UID=www-data
		APP_CONFIG_AVAIL=$ETC_DIR/apps-available/$APP_NAME.ini
		APP_CONFIG_ENABLED=$ETC_DIR/apps-enabled/$APP_NAME.ini
		APP_CONFIG_FILES="$APP_CONFIG_AVAIL $APP_CONFIG_ENABLED"
		;;
	    (opensuse-*)
		APP_GID=nogroup
		APP_UID=nobody
		APP_CONFIG=$ETC_DIR/vassals/$APP_NAME.ini
		APP_CONFIG_FILES="$APP_CONFIG"
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
APP_PIDFILE=$RUN_DIR/pid
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
sudo mkdir -p $APP_DIR $VAR_DIR

# Install virtual environment
if install_venv; then

    # Install application
    install_app

    # Configure application
    configure_app $APP_CONFIG_FILES

    # Restart application
    restart_app

fi
