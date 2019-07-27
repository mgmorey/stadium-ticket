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

GREP_REGEX='^%s(\.[0-9]+){0,2}$\n'
PIP_9_UPGRADE_OPTS="--no-cache-dir"
PIP_10_UPGRADE_OPTS="--no-cache-dir --no-warn-script-location"

activate_virtualenv() {
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1/bin -a -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
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
    virtualenv=$("$script_dir/get-python-command.sh" virtualenv)

    if [ "$virtualenv" = false ]; then
	pyvenv=$("$script_dir/get-python-command.sh" pyvenv)
    fi

    if [ "$virtualenv" != false ]; then
	if [ -z "${python-${2-}}" ]; then
	    boot_python=$(find_bootstrap_python)
	    python=$(find_user_python $boot_python)

	    if ! "$script_dir/check-python.sh" $python; then
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

find_bootstrap_python() (
    for version in $PYTHON_VERSIONS ""; do
	if python$version --version >/dev/null 2>&1; then
	    printf "%s\n" "python$version"
	    return 0
	fi
    done

    abort "%s\n" "No Python interpreter found in PATH"
)

find_pyenv_python() (
    assert [ $# -eq 2 ]
    assert [ -n "$1" ]
    assert [ -n "$2" ]
    pythons="$(ls $1/versions/$2.*/bin/python 2>/dev/null | sort -r)"

    for python in $pythons; do
	if $python --version >/dev/null 2>&1; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
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

    for version in $python_versions $PYTHON_VERSIONS; do
	python=$($which python$version 2>/dev/null || true)

	if [ -n "$python" ]; then
	    printf "%s\n" "$python"
	    return 0
	fi
    done

    return 1
)

get_home_directory() {
    case "$kernel_name" in
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

get_pyenv_versions() {
    pyenv install --list | awk 'NR > 1 {print $1}' | grep_pyenv_version ${1-}
}

get_required_python_versions() (
    boot_python=$(find_bootstrap_python)
    python_versions=$($boot_python "$script_dir/check-python.py" --delim '\.')

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	if get_pyenv_versions $python_version; then
	    return 0
	fi
    done

    return 1
)

grep_pyenv_version() {
    assert [ $# -le 1 ]

    if [ $# -eq 1 ]; then
	grep -E $(printf "$GREP_REGEX" "$1" 2>/dev/null)
    else
	cat
    fi
}

install_python_version() (
    version=${1-$(get_required_python_versions | sort -r | head -n 1)}

    if [ -n "$version" ]; then
	pyenv install -s $version
    fi
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
    pip=$("$script_dir/get-python-command.sh" pip)

    if [ "$pip" = false ]; then
	return
    fi

    printf "%s\n" "Upgrading user packages via pip"
    $pip install $(get_pip_upgrade_options) --upgrade --user "$@"
)
