#!/bin/sh -eu

# Application-specific parameters
APP_NAME=stadium-ticket
APP_PORT=5000

# Distro-specific parameters
APP_GID=www-data
APP_UID=www-data

abort() {
    printf "$@" >&2
    exit 1
}

check_workdir() {
    if [ -n "$APP_DIR" -a "$SOURCE_DIR" = "$APP_DIR" ]; then
	abort "%s\n" "Change to source directory before running this script"
    fi
}

create_virtual_env() {
    (cd $APP_DIR

     if sudo -H pipenv >/dev/null 2>&1; then
	 export LANG=C.UTF-8
	 export LC_ALL=C.UTF-8
	 export PIPENV_VENV_IN_PROJECT=true
	 sudo -H pipenv install
	 venv="$(sudo -H pipenv --venv)"

	 if [ -n "$venv" ]; then
	     sudo mkdir -p $APP_DIR/.venv
	     sudo sh -c "cp -R $venv/* $APP_DIR/.venv/"
	 fi
     fi)
}

install_app() {
    (cd "$SOURCE_DIR"
     check_workdir

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
     sudo chown -R $APP_UID:$APP_GID $APP_DIR $VAR_DIR

     # Install application uWSGI configuration
     if [ -d $ETC_DIR/apps-available ]; then
	 print_filter app.ini | sh | sudo sh -c "cat >$APP_AVAIL"
	 if [ -d $ETC_DIR/apps-enabled ]; then
	     sudo ln -sf $APP_AVAIL $APP_ENABLED
	 fi
     fi)
}

print_filter() {
    printf "%s" "sed"

    for var in APP_NAME APP_PORT APP_GID APP_UID APP_DIR; do
	eval value="\$$var"
	printf -- " -e 's|\$(%s)|%s|g'" "$var" "$value"
    done

    printf " %s\n" "$@"
}

restart_app() {
    # Send restart signal to app
    if [ -r $APP_PIDFILE ]; then
	PID=$(cat $APP_PIDFILE)

	if [ -n "$PID" ]; then
	    sudo kill -s HUP $PID
	fi
    fi
}

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
ETC_DIR=/etc/uwsgi
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

# Set application filenames using directory variables
APP_AVAIL=$ETC_DIR/apps-available/$APP_NAME.ini
APP_ENABLED=$ETC_DIR/apps-enabled/$APP_NAME.ini
APP_PIDFILE=$RUN_DIR/pid

SCRIPT_DIR="$(dirname $0)"
SOURCE_DIR="$(readlink -f "$SCRIPT_DIR/..")"

# Remove application and uWSGI configuration
sudo /bin/rm -rf $APP_ENABLED $APP_AVAIL $APP_DIR

cd "$SOURCE_DIR"
check_workdir

# Create application directories
sudo mkdir -p $APP_DIR $VAR_DIR

# Install application Pipfiles and requirements.txt
sudo /bin/cp Pipfile Pipfile.lock requirements.txt $APP_DIR/

# Install dependencies in Pipfiles
create_virtual_env

# Install application
install_app

# Restart application
restart_app
