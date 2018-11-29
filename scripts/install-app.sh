#!/bin/sh -eu

APP_NAME=stadium-ticket
APP_PORT=5000

abort() {
    printf "$@" >&2
    exit 1
}

configure_app() {
    (cd "$SOURCE_DIR"

     case "$kernel_name" in
	 (Linux)
	     case "$distro_name" in
		 (debian|ubuntu)
		     APP_AVAIL=$ETC_DIR/apps-available/$APP_NAME.ini
		     APP_ENABLED=$ETC_DIR/apps-enabled/$APP_NAME.ini

		     if [ -d $ETC_DIR/apps-available ]; then
			 generate app.ini | sh | sudo sh -c "cat >$APP_AVAIL"
			 if [ -d $ETC_DIR/apps-enabled ]; then
			     sudo ln -sf $APP_AVAIL $APP_ENABLED
			 fi
		     fi
		     ;;
		 (opensuse-*)
		     APP_VASSAL=$ETC_DIR/vassals/$APP_NAME.ini

		     if [ -d $ETC_DIR/vassals ]; then
			 generate app.ini | sh | sudo sh -c "cat >$APP_VASSAL"
		     fi
		     ;;
	     esac
	     ;;
     esac)
}

generate() {
    printf "%s" sed

    for var in APP_NAME APP_PORT APP_GID APP_UID APP_DIR; do
	eval value="\$$var"
	printf -- " -e 's|\$(%s)|%s|g'" "$var" "$value"
    done

    printf " %s\n" "$@"
}

install_app() {
    (cd "$SOURCE_DIR"

     for file in .env app/*; do
	 if [ -r "$file" ]; then
	     case "$file" in
		 (*/GNUmakefile|*/Makefile|*/test_*)
		     printf "Skipping %s\n" "$file"
		     ;;
		 (*)
		     printf "Copying %s to %s\n" "$file" $APP_DIR/
		     sudo /bin/cp -R "$file" $APP_DIR/
		     ;;
	     esac
	 fi
     done

     # Make application owner of its own directories
     sudo chown -R $APP_UID:$APP_GID $APP_DIR $VAR_DIR)
}

install_venv() {
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export PIPENV_VENV_IN_PROJECT=true

    if pipenv >/dev/null; then
	(cd $SOURCE_DIR && sudo /bin/cp $APP_PIPFILES $APP_DIR)
	(cd $APP_DIR

	 if sudo -H pipenv install; then
	     venv="$(sudo -H pipenv --venv)"

	     if [ -n "$venv" ]; then
		 sudo mkdir -p $APP_DIR/.venv
		 sudo sh -c "cp -R $venv/* $APP_DIR/.venv/"
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

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

# Set distro-specific parameters
case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu)
		APP_GID=www-data
		APP_UID=www-data
		;;
	    (opensuse-*)
		APP_GID=nogroup
		APP_UID=nobody
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

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
ETC_DIR=/etc/uwsgi
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

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
    configure_app

    # Restart application
    restart_app

fi
