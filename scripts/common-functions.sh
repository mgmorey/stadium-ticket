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

GREP_REGEX='^%s(\.[0-9]+){0,2}$\n'

WAIT_SIGNAL=10

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
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    agent_label=local.$APP_NAME
    agent_target=$HOME/Library/LaunchAgents/$agent_label.plist

    case $1 in
	(load)
	    assert [ $# -eq 2 ]
	    assert [ -n "$2" ]
	    $2 $agent_target

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
	    assert [ $# -eq 2 ]
	    assert [ -n "$2" ]

	    if [ $dryrun = false -a -e $agent_target ]; then
		launchctl unload $agent_target
	    fi

	    $2 $agent_target
	    ;;
    esac
)

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
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

find_system_python() (
    for prefix in /usr /usr/local; do
	python_dir=$prefix/bin

	if [ -d $python_dir ]; then
	    for version in $PYTHON_VERSIONS; do
		python=$python_dir/python$version

		if [ -x $python ]; then
		    if $python --version >/dev/null 2>&1; then
			printf "%s\n" "$python"
			return 0
		    fi
		fi
	    done
	fi
    done

    return 1
)

find_user_python() (
    bootstrap_python=$(find_bootstrap_python)
    python_versions=$($bootstrap_python "$script_dir/check-python.py")

    if pyenv --version >/dev/null 2>&1; then
	pyenv_root="$(pyenv root)"
	which="pyenv which"
    else
	pyenv_root=
	which=which
    fi

    if [ -n "$pyenv_root" ]; then
	for version in ${python_versions-$PYTHON_VERSIONS}; do
	    python=$(find_pyenv_python $pyenv_root $version || true)

	    if [ -z "$python" ]; then
		install_python_version >&2
		python=$(find_pyenv_python $pyenv_root $version)
	    fi

	    if [ -n "$python" ]; then
		printf "%s\n" "$python"
		return 0
	    fi
	done
    fi

    for version in ${python_versions-$PYTHON_VERSIONS}; do
	python=$($which python$version 2>/dev/null || true)

	if [ -n "$python" ]; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

find_pyenv_python() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" -a -n "$2" ]
    pythons="$(ls $1/versions/$2.*/bin/python 2>/dev/null | sort -Vr)"

    for python in $pythons; do
	if $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

get_home_directory() {
    getent passwd ${1-$USER} | awk -F: '{print $6}'
}

get_pyenv_versions() {
    pyenv install --list | awk 'NR > 1 {print $1}' | grep_pyenv_version ${1-}
}

get_required_python_versions() (
    python=$(find_bootstrap_python)
    python_versions=$($python "$script_dir/check-python.py" --delim '\.')

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	if get_pyenv_versions $python_version; then
	    return 0
	fi
    done

    return 1
)

grep_pyenv_version() {
    assert [ $# -eq 0 -o $# -eq 1 ]

    if [ $# -eq 1 ]; then
	grep -E $(printf "$GREP_REGEX" "$1")
    else
	cat
    fi
}

install_python_version() (
    version=${1-$(get_required_python_versions | sort -Vr | head -n 1)}

    if [ -n "$version" ]; then
	pyenv install -s $version
    fi
)

print_logs() {
    assert [ $# -eq 1 -o $# -eq 2 ]
    assert [ -n "$1" ]

    if [ -r $1 ]; then
	tail $1 | print_table "SERVICE LOG $1 (last 10 lines)" ${2-}
    elif [ -e $1 ]; then
	printf "%s: No permission to read file\n" "$1" >&2
    fi
}

print_table() {
    awk -v columns="${COLUMNS-96}" -v header="$1" -v footer="${2-1}" '
	function truncate(s) {
	    return substr(s, 1, columns)
	}
	  BEGIN {if (columns < 80)
		     columns = 80;
		 if (columns > 240)
		     columns = 240;
		 dashes = "";
		 for (i = 0; i < columns; i++)
		     dashes = dashes "-";
		 equals = "";
		 for (i = 0; i < columns; i++)
		     equals = equals "="}
	NR == 1 {line1 = $0}
	NR == 2 {printf("%s\n", truncate(equals));
		 if (header)
		     printf("%s\n%s\n%s\n",
			    truncate(header),
			    truncate(dashes),
			    truncate(line1));
		 else
		     printf("%s\n%s\n",
			    truncate(line1),
			    truncate(dashes))}
	NR >= 2 {printf("%s\n", truncate($0))}
	    END {if (footer)
		     printf("%s\n", truncate(equals))}'
}

reset_home_directory() {
    if [ -z "${SUDO_USER-}" ]; then
	return 0
    fi

    home_dir="$(get_home_directory $SUDO_USER)"

    if [ "$HOME" != "$home_dir" ]; then
	export HOME="$home_dir"
    fi
}

signal_process_and_poll() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 ]
    i=0

    while kill -s $2 $1 2>/dev/null && [ $i -lt $3 ]; do
	if [ $i -eq 0 ]; then
	    printf "%s\n" "Waiting for process to exit"
	fi

	sleep 1
	i=$((i + 1))
    done

    elapsed=$((elapsed + i))
    test $i -lt $3
    return $?
}

signal_process_and_wait() {
    assert [ $# -eq 3 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    assert [ -n "$3" ]
    assert [ $3 -ge 0 ]

    if kill -s $2 $1 2>/dev/null; then
	printf "Waiting for process to handle SIG%s\n" "$2"
	sleep $3
	elapsed=$((elapsed + $3))
	result=0
    else
	result=1
    fi

    return $result
}

signal_service() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    assert [ $1 -gt 0 ]
    elapsed=0
    wait=$1
    shift

    pid=$(cat $APP_PIDFILE 2>/dev/null)

    if [ -z "$pid" ]; then
	return 1
    fi

    for signal in "$@"; do
	printf "Sending SIG%s to process (PID: %s)\n" $signal $pid

	case $signal in
	    (HUP)
		if signal_process_and_wait $pid $signal $wait; then
		    return 0
		fi
		;;
	    (*)
		if signal_process_and_poll $pid $signal $wait; then
		    return 0
		fi
		;;
	esac
    done

    return 1
}
