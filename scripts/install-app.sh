#!/bin/sh -eu

print_sed_command() {
    printf "%s" "sed"
	  
    for var in APP_NAME APP_PORT APP_GID APP_UID APP_DIR; do
	eval value="\$$var"
	printf -- " -e 's|\$(%s)|%s|g'" "$var" "$value"
    done

    printf " %s\n" "$@"
}

CWD="$(pwd)"

# Application-specific parameters
APP_NAME=stadium-ticket
APP_PORT=5000

# Distro-specific parameters
APP_GID=www-data
APP_UID=www-data
DEBIAN_FRONTEND=noninteractive
RETRY_LOOP="for i in 1 2 3; do %s && break; done\n"

# Update Debian package repository index
APT_UPDATE="apt-get update -qqy"
printf "$RETRY_LOOP" "$APT_UPDATE" | sudo sh

# Install dependencies from Debian package repository
APT_INSTALL="apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip uwsgi uwsgi-plugin-python3"
printf "$RETRY_LOOP" "$APT_INSTALL" | sudo sh

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
ETC_DIR=/etc/uwsgi
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

if [ "$CWD" = $APP_DIR ]; then
    printf "Change directories before running this script\n"
    exit 1
fi

# Set application filenames using directory variables
APP_AVAILABLE=$ETC_DIR/apps-available/$APP_NAME.ini
APP_ENABLED=$ETC_DIR/apps-enabled/$APP_NAME.ini
APP_PIDFILE=$RUN_DIR/pid

# Remove application and uWSGI configuration
sudo /bin/rm -rf $APP_ENABLED $APP_AVAILABLE $APP_DIR

# Create application directories
sudo mkdir -p $APP_DIR $VAR_DIR

# Install application Pipfiles and requirements.txt
sudo /bin/cp Pipfile* requirements.txt $APP_DIR/

# Change working directory
cd $APP_DIR

# Install dependencies in Pipfiles

if sudo -H pipenv >/dev/null 2>&1; then
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export PIPENV_VENV_IN_PROJECT=true
    sudo -H pipenv install
    virtualenv="$(sudo -H pipenv --venv)"

    if [ -n "$virtualenv" ]; then
	sudo mkdir -p $APP_DIR/.venv
	sudo sh -c "cp -R $virtualenv/* $APP_DIR/.venv/"
    fi
fi

# Change working directory
cd "$CWD"

if [ "$CWD" = $APP_DIR ]; then
    printf "Change directories before running this script\n"
    exit 1
fi

# Copy application files to application directory
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
    print_sed_command "$CWD/app.ini" | sh | sudo sh -c "cat >$APP_AVAILABLE"
    if [ -d $ETC_DIR/apps-enabled ]; then
	sudo ln -sf $APP_AVAILABLE $APP_ENABLED
    fi
fi

# Send reload/restart signal to uWSGI
if [ -r $APP_PIDFILE ]; then
    PID=$(cat $APP_PIDFILE)

    if [ -n "$PID" ]; then
	sudo kill -s HUP $PID
    fi
fi
