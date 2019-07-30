# -*- Mode: Shell-script -*-

# common-functions.sh: define commonly used shell functions
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

FORMAT_RE='^%s(\.[0-9]+){0,2}$\n'

PIP_9_UPGRADE_OPTS="--no-cache-dir"
PIP_10_UPGRADE_OPTS="--no-cache-dir --no-warn-script-location"

PKGSRC_PREFIXES=$(ls -d /opt/local /usr/pkg 2>/dev/null || true)
SYSTEM_PREFIXES="/usr/local${PKGSRC_PREFIXES:+ $PKGSRC_PREFIXES} /usr"

activate_virtualenv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
}

check_python() {
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]

    printf "Python %s interpreter found: %s\n" "$2" "$1"

    if ! "$1" "$script_dir/check-python.py" $2; then
	return 1
    fi

    return 0
}

create_tmpfile() {
    tmpfile=$(mktemp)
    assert [ -n "${tmpfile}" ]
    tmpfiles="${tmpfiles+$tmpfiles }$tmpfile"
    trap "/bin/rm -f $tmpfiles" EXIT INT QUIT TERM
}

create_virtualenv() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    virtualenv=$(get_python_command virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$(get_python_command pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	if [ -z "${python-${2-}}" ]; then
	    triplet=$(find_system_python)
	    versions="${triplet#* }"
	    version="${versions#* }"
	    python="${triplet%% *}"

	    if ! check_python $python $version; then
		abort "%s\n" "No suitable Python interpreter found"
	    fi
	fi
    fi

    printf "%s\n" "Creating virtual environment"

    if [ "$virtualenv" != false ]; then
	$virtualenv -p $python $1
    elif [ "$pyvenv" != false ]; then
	$pyvenv $1
    else
	abort "%s: No virtualenv nor pyenv/venv command found\n" "$0"
    fi
)

find_system_python() {
    find_system_pythons | head -n 1
}

find_system_pythons() (
    for python_version in $PYTHON_VERSIONS; do
	for system_prefix in $SYSTEM_PREFIXES; do
	    if [ -x $system_prefix/bin/python$python_version ]; then
		python=$system_prefix/bin/python$python_version
		python_output="$($python --version)"

		if [ -n "$python_output" ]; then
		    printf "%s %s %s\n" "$python" "$python_version" "${python_output#Python }"
		fi
	    fi
	done
    done
)

find_user_python() (
    python_versions=$($1 "$script_dir/check-python.py")

    if pyenv --version >/dev/null 2>&1; then
	pyenv_root="$(pyenv root)"
	which="pyenv which"
    else
	pyenv_root=
	which=which
    fi

    if [ -n "$pyenv_root" ]; then
	for version in $python_versions $PYTHON_VERSIONS; do
	    python=$(find_user_python_installed $pyenv_root $version || true)

	    if [ -z "$python" ]; then
		install_python_version >&2
		python=$(find_user_python_installed $pyenv_root $version)
	    fi

	    if [ -n "$python" ]; then
		printf "%s\n" "$python"
		return 0
	    fi
	done
    fi

    for version in $python_versions $PYTHON_VERSIONS; do
	python=$($which python$version 2>/dev/null || true)

	if [ -n "$python" ]; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

find_user_python_installed() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    sort_versions=$(get_sort_command)
    pythons="$(ls $1/versions/$2.*/bin/python 2>/dev/null | $sort_versions)"

    for python in $pythons; do
	if $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

get_home_directory() {
    case "$(uname -s)" in
	(Darwin)
	    printf "/Users/%s\n" "${1-USER}"
	    ;;
	(*)
	    getent passwd ${1-$USER} | awk -F: '{print $6}'
	    ;;
    esac
}

get_pip_upgrade_options() {
    case "$($pip --version | awk '{print $2}')" in
	([0-9].*)
	    printf "%s\n" "$PIP_9_UPGRADE_OPTS"
	    ;;
	(*)
	    printf "%s\n" "$PIP_10_UPGRADE_OPTS"
	    ;;
    esac
}

get_python_command() (
    name="$1"
    shift

    case "$name" in
	(pip|pipenv|virtualenv)
	    for version in "" $PYTHON_VERSIONS; do
		for command in $name$version $name "python$version -m $name" false; do
		    if $command --help >/dev/null 2>&1; then
			printf "%s\n" "$command"
			return 0
		    fi
		done
	    done
	    ;;
	(pyvenv)
	    for version in "" $PYTHON_VERSIONS; do
		for command in "python$version -m venv" false; do
		    if $command --help >/dev/null 2>&1; then
			printf "%s\n" "$command"
			return 0
		    fi
		done
	    done
	    ;;
	(*)
	    abort "%s: Invalid command/module '%s'\n" "$0" "$name"
    esac

    printf "%s\n" "$command"
)

get_sort_command() {
    case "$(uname -s)" in
	(NetBSD)
	    printf "%s\n" "sort -r"
	    ;;
	(*)
	    printf "%s\n" "sort -Vr"
	    ;;
    esac
}

get_versions_all() {
    pyenv install --list | awk 'NR > 1 {print $1}' | grep_version ${1-}
}

get_versions_passed() (
    python=$(find_system_python | awk '{print $1}')
    python_versions=$($python "$script_dir/check-python.py" --delim '\.')

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	if get_versions_all $python_version; then
	    return 0
	fi
    done

    return 1
)

grep_version() {
    assert [ $# -le 1 ]

    if [ $# -eq 1 ]; then
	grep -E $(printf "$FORMAT_RE" "$1" 2>/dev/null) 2>/dev/null
    else
	cat
    fi
}

install_python_version() (
    sort_versions=$(get_sort_command)
    pyenv install -s ${1-$(get_versions_passed | $sort_versions | head -n 1)}
)

set_unpriv_environment() {
    if [ -z "${SUDO_USER-}" ]; then
	return 0
    fi

    home_dir="$(get_home_directory $SUDO_USER)"

    if [ "$HOME" != "$home_dir" ]; then
	export HOME="$home_dir"

        if [ -r $HOME/.profile ]; then
            set +u
            . $HOME/.profile
            set -u
        fi
    fi
}

sync_requirements_via_pip() {
    printf "%s\n" "Installing required packages via pip"
    $pip install $(printf -- "-r %s\n" ${venv_requirements:-requirements.txt})
}

sync_virtualenv_via_pip() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    if [ -n "${VIRTUAL_ENV:-}" -a -d "$1" ]; then
	stats_1="$(stat -Lf "%d %i" "$VIRTUAL_ENV")"
	stats_2="$(stat -Lf "%d %i" "$1")"

	if [ "$stats_1" = "$stats_2" ]; then
	    abort "%s: Must not be run within the virtual environment\n" "$0"
	fi
    fi

    if [ -d $1 ]; then
	sync=false
    else
	sync=true
    fi

    if [ $sync = true ]; then
	upgrade_via_pip pip virtualenv
	create_virtualenv "$@"
    fi

    if [ -r $1/bin/activate ]; then
	activate_virtualenv $1
	assert [ -n "${VIRTUAL_ENV:-}" ]

	if [ "${venv_force_sync:-$sync}" = true ]; then
	    sync_requirements_via_pip
	fi
    elif [ -d $1 ]; then
	abort "%s: Unable to activate environment\n" "$0"
    else
	abort "%s: No virtual environment\n" "$0"
    fi
}

upgrade_via_pip() (
    pip=$(get_python_command pip)

    if [ "$pip" = false ]; then
	return
    fi

    printf "%s\n" "Upgrading user packages via pip"
    $pip install $(get_pip_upgrade_options) --upgrade --user "$@"
)
