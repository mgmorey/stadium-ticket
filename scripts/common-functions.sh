# -*- Mode: Shell-script -*-

# common-functions.sh: define commonly-used shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

GREP_REGEX='^  %s([.]\d+){0,2}$'

KILL_COUNT=20
KILL_INTERVAL=10

LINE_SINGLE="----------------------------------------"
LINE_DOUBLE="========================================"

abort_insufficient_permissions() {
    cat <<-EOF >&2
	$0: Write access required to update file or directory: $1
	$0: Insufficient access to complete the requested operation.
	$0: Please try the operation again as a privileged user.
	EOF
    exit 1
}

abort_not_supported() {
    abort "%s: %s: %s not supported\n" "$0" "$PRETTY_NAME" "$*"
}

abort_no_python() {
    abort "%s\n" "No suitable Python interpreter found"
}

check_permissions() (
    for file; do
	if [ -e $file -a -w $file ]; then
	    :
	else
	    dir=$(dirname $file)

	    if [ $dir != . -a $dir != / ]; then
		check_permissions $dir
	    else
		abort_insufficient_permissions $file
	    fi
	fi
    done
)

check_python() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -x $1 ]
    python_output="$($1 --version || true)"

    if [ -z "$python_output" ]; then
	abort_no_python
    fi

    version="${python_output#Python }"
    printf "Python %s interpreter found: %s\n" "$version" "$1"

    if ! $1 "$script_dir/check-python.py" "$version"; then
	abort_no_python
    fi
)

control_launch_agent() (
    assert [ -n "$1" ]
    agent_label=local.$APP_NAME
    agent_target=$HOME/Library/LaunchAgents/$agent_label.plist

    case $1 in
	(load)
	    generate_launch_agent_plist $agent_target

	    if [ $dryrun = false ]; then
		launchctl load $agent_target
	    fi
	    ;;
	(restart)
	    control_launch_agent stop
	    control_launch_agent start
	    ;;
	(start|stop)
	    if [ $dryrun = false -a $1 = start -o -e $agent_target ]; then
		launchctl $1 $agent_label
	    fi
	    ;;
	(unload)
	    if [ $dryrun = false -a -e $agent_target ]; then
		launchctl unload $agent_target
	    fi

	    remove_files $agent_target
	    ;;
    esac
)

create_symlink() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    check_permissions "$2"

    if [ $dryrun = false ]; then
	assert [ -r "$1" ]

	if [ $1 != $2 -a ! -e $2 ]; then
	    printf "Creating link %s\n" "$2"
	    /bin/ln -s $1 $2
	fi
    fi
}

create_tmpfile() {
    tmpfile=$(mktemp)
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

find_bootstrap_python() (
    for python in python3 python2 python false; do
	if $python --version >/dev/null 2>&1; then
	    break
	fi
    done

    if [ $python = false ]; then
	abort_no_python
    fi

    printf "%s\n" "$python"
)

find_container_python () (
    python=$(find_bootstrap_python)
    python_versions=$($python "$script_dir/check-python.py")

    for prefix in /usr /usr/local; do
	python_dir=$prefix/bin

	if [ -d $python_dir ]; then
	    for version in ${python_versions-$PYTHON_VERSIONS}; do
		python=$python_dir/python$version

		if [ -x $python ]; then
		    if $python --version >/dev/null 2>&1; then
			printf "%s\n" "$python"
			return
		    fi
		fi
	    done
	fi
    done
)

find_development_python() (
    python=$(find_bootstrap_python)
    python_versions=$($python "$script_dir/check-python.py")

    if pyenv --version >/dev/null 2>&1; then
	pyenv_root="$(pyenv root)"
	which="pyenv which"
    else
	pyenv_root=
	which=which
    fi

    if [ -n "$pyenv_root" ]; then
	for version in ${python_versions-$PYTHON_VERSIONS}; do
	    python=$(find_pyenv_python $pyenv_root $version)

	    if [ -z "$python" ]; then
		install_python_version >&2
		python=$(find_pyenv_python $pyenv_root $version)
	    fi

	    if [ -n "$python" ]; then
		printf "%s\n" "$python"
		return
	    fi
	done
    fi

    for version in ${python_versions-$PYTHON_VERSIONS}; do
	python=$($which python$version 2>/dev/null || true)

	if [ -z "$python" ]; then
	    :
	elif [ $python = false ]; then
	    abort_no_python
	elif $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return
	fi
    done
)

find_pyenv_python() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]
    pythons="$(ls $1/versions/$2.*/bin/python 2>/dev/null | sort -Vr)"

    for python in $pythons; do
	if $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return
	fi
    done
)

generate_launch_agent_plist() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    check_permissions $1
    create_tmpfile
    cat <<-EOF >$tmpfile
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

    if [ $dryrun = false ]; then
	printf "Generating file %s\n" "$1"
	install -d -m 755 $(dirname $1)
	install -C -m 644 $tmpfile $1
    fi
)

get_pyenv_versions() (
    version_as_regex=$(printf "%s\n" $1 | sed 's/\./\\./')
    regex=$(printf "$GREP_REGEX" "$version_as_regex")
    pyenv install --list | egrep "$regex" | sort -Vr
)

get_required_python_version() {
    python=$(find_bootstrap_python)
    python_versions=$($python "$script_dir/check-python.py")

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	get_pyenv_versions $python_version | head -n 1
	return
    done
}

get_setpriv_command() (
    assert [ -n "$1" ]
    rgid="$(id -g $1)"
    ruid="$(id -u $1)"
    setpriv_opts="--clear-groups --rgid $rgid --ruid $ruid"
    setpriv_version="$(setpriv --version 2>/dev/null)"

    case "${setpriv_version##* }" in
	(2.3[3456789].*|2.[456789]?.*|[3456789].*)
	    setpriv_opts="$setpriv_opts --reset-env"
	    ;;
	(2.3[12].*)
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
    assert [ -n "$1" -a -n "$2" -a -r "$2" -a -n "$3" ]
    check_permissions $3

    if [ $dryrun = false ]; then
	if is_tmpfile $2; then
	    printf "Generating file %s\n" "$3"
	else
	    printf "Installing file %s as %s\n" "$2" "$3"
	fi

	install -d -m 755 "$(dirname "$3")"
	install -C -m $1 $2 $3
    fi
}

install_python_version() {
    pyenv install -s ${1-$(get_required_python_version)}
}

is_tmpfile() {
    printf "%s\n" ${tmpfiles-} | grep $1 >/dev/null
}

print_file_tail() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    create_tmpfile
    tail $1 >$tmpfile

    if [ ! -s "$tmpfile" ]; then
	return
    fi

    printf "%s\n" $LINE_DOUBLE$LINE_DOUBLE
    printf "%s\n" "Contents of $1 (last 10 lines)"
    printf "%s\n" $LINE_SINGLE$LINE_SINGLE
    cat $tmpfile
    printf "%s\n" $LINE_DOUBLE$LINE_DOUBLE
}

remove_files() {
    check_permissions "$@"

    if [ "$dryrun" = false ]; then
	printf "Removing %s\n" "$@" | sort -u
	/bin/rm -rf "$@"
    fi
}

shell() (
    assert [ $# -ge 1 ]

    if [ "$(id -u)" -eq 0 -a -n "${SUDO_USER:-}" ]; then
	setpriv=$(get_setpriv_command $SUDO_USER)

	if [ -z "$setpriv" ]; then
	    setpriv="su -l $SUDO_USER"
	fi

	eval $setpriv "$@"
    else
	eval "$@"
    fi
)

signal_service() {
    pid=$(cat $APP_PIDFILE 2>/dev/null)
    result=1

    if [ -z "$pid" ]; then
	return $result
    fi

    for signal in "$@"; do
	if [ $result -gt 0 ]; then
	    printf "Sending SIG%s to process (pid: %s)\n" $signal $pid
	fi

	if [ $signal = HUP ]; then
	    if kill -s $signal $pid 2>/dev/null; then
		printf "Waiting for process to handle SIG%s\n" "$signal"
		sleep $KILL_INTERVAL
		result=0
	    else
		break
	    fi
	else
	    printf "%s\n" "Waiting for process to exit"
	    i=0

	    while kill -s $signal $pid 2>/dev/null && [ $i -lt $KILL_COUNT ]; do
		sleep 1
		i=$((i + 1))
	    done

	    if [ $i -lt $KILL_COUNT ]; then
		result=0
		break
	    fi
	fi
    done

    return $result
}

tail_file() {
    assert [ -n "$1" ]

    if [ -r $1 ]; then
	print_file_tail $1
    elif [ -e $1 ]; then
	printf "%s: No permission to read file\n" "$1" >&2
    fi
}
