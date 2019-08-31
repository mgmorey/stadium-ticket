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
    python=${2-}

    if [ -z "${python-}" ]; then
	python=$(find_system_python | /usr/bin/awk '{print $1}')
	python=$(find_user_python $python)
	python_output="$($python --version)"
	python_version="${python_output#Python }"

	if ! check_python "$python" "$python_version"; then
	    abort "%s\n" "No suitable Python interpreter found"
	fi
    fi

    printf "%s\n" "Creating virtual environment"

    for utility in $VENV_UTILITIES; do
	command=$(eval get_command -p $python $utility || true)

	if [ -z "$command" ]; then
	    continue
	fi

	case "$utility" in
	    (pyvenv)
		$command $1
		return $?
		;;
	    (virtualenv)
		$command -p $python $1
		return $?
		;;
	    (*)
		continue
		;;
	esac
    done

    abort "%s: No virtualenv utility found\n" "$0"
)

find_python() (
    python=$(find_system_python | /usr/bin/awk '{print $1}')
    python=$(find_user_python $python)
    python_output="$($python --version)"
    python_version="${python_output#Python }"

    if ! check_python "$python" "$python_version" >&2; then
	abort "%s\n" "No suitable Python interpreter found"
    fi

    printf "%s\n" "$python"
)

find_system_python() {
    find_system_pythons | head -n 1
}

find_system_pythons() (
    for suffix in $PYTHON_VERSIONS; do
	for system_prefix in $SYSTEM_PREFIXES; do
	    if [ -x $system_prefix/bin/python$suffix ]; then
		python=$system_prefix/bin/python$suffix
		output="$($python --version)"

		if [ -n "$output" ]; then
		    version="${output#Python }"
		    printf "%s %s %s\n" "$python" "$suffix" "$version"
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
	for version in $python_versions; do
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

    for version in $python_versions; do
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

get_command() (
    assert [ $# -ge 1 ]

    if [ $# -ge 1 ] && [ "$1" = -p ]; then
	dirname="$(dirname "$2")"
	python="$2"
	versions="${2#*python}"
	shift 2
    else
	dirname=
	python=python
	versions=
    fi

    if [ $# -ge 1 ] && [ "$1" = -v ]; then
	if [ -z "${versions}" ]; then
	    versions="$2"
	fi

	shift 2
    fi

    assert [ $# -eq 1 ]
    basename="$1"

    case "$basename" in
	(pyvenv)
	    module=venv
	    option=--help
	    ;;
	(*)
	    module=$basename
	    option=--version
	    ;;
    esac

    utility="${dir:+$dir/}$basename"

    if [ -n "${versions-}" ]; then
	for version in $versions; do
	    if get_command_helper "$dirname" "$basename" $version; then
		return 0
	    fi
	done
    elif get_command_helper "$dirname" "$basename"; then
	return 0
    fi

    return 1
)

get_command_helper() (
    if ! expr "$2" : pyvenv >/dev/null; then
	script=${1:+$1/}$2${3-}
    else
	script=
    fi

    for command in $script "$python -m $module"; do
	if $command $option >/dev/null 2>&1; then
	    printf "%s\n" "$command"
	    return 0
	fi
    done

    return 1
)

get_file_metadata() {
    assert [ $# -eq 2 ]

    case "${kernel_name=$(uname -s)}" in
	(GNU|Linux|SunOS)
	    /usr/bin/stat -Lc "$@"
	    ;;
	(Darwin|FreeBSD)
	    /usr/bin/stat -Lf "$@"
	    ;;
    esac
}

get_home_directory() {
    assert [ $# -eq 1 ]

    case "${kernel_name=$(uname -s)}" in
	(Darwin)
	    printf "/Users/%s\n" "$1"
	    ;;
	(*)
	    getent passwd "$1" | /usr/bin/awk -F: '{print $6}'
	    ;;
    esac
}

get_pip_options() {
    if [ "$(id -u)" -eq 0 ]; then
	printf "%s\n" "--no-cache-dir --quiet"
    fi
}

get_pip_requirements() {
    printf -- "-r %s\n" ${venv_requirements:-requirements.txt}
}

get_sort_command() {
    case "${kernel_name=$(uname -s)}" in
	(NetBSD)
	    printf "%s\n" "sort -r"
	    ;;
	(*)
	    printf "%s\n" "sort -Vr"
	    ;;
    esac
}

get_user_name() {
    printf "%s\n" "${SUDO_USER-${USER-${LOGNAME}}}"
}

get_versions_all() {
    pyenv install --list | /usr/bin/awk 'NR > 1 {print $1}' | grep_version ${1-}
}

get_versions_passed() (
    python=$(find_system_python | /usr/bin/awk '{print $1}')
    python_versions=$($python "$script_dir/check-python.py" --delim '\.')

    for python_version in ${python_versions-$PYTHON_VERSIONS}; do
	if get_versions_all $python_version; then
	    return 0
	fi
    done

    return 1
)

grep_path() {
    printf "%s\n" "$1" | /usr/bin/awk 'BEGIN {RS=":"} {print $0}' | grep -q "$2"
}

grep_version() {
    assert [ $# -le 1 ]

    if [ $# -eq 1 ]; then
	grep -E $(printf "$FORMAT_RE" "$1" 2>/dev/null) 2>/dev/null
    else
	cat
    fi
}

have_same_device_and_inode() (
    stats_1="$(get_file_metadata %d:%i "$1")"
    stats_2="$(get_file_metadata %d:%i "$2")"

    if [ "$stats_1" = "$stats_2" ]; then
	return 0
    else
	return 1
    fi
)

install_python_version() (
    python=${1-$(get_versions_passed | $(get_sort_command) | head -n 1)}

    if [ -z "$python" ]; then
	return 1
    fi

    pyenv install -s $python
)

install_via_pip() (
    $pip install${pip_options+ $pip_options} "$@"
)

refresh_via_pip() {
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]

    if [ -n "${VIRTUAL_ENV:-}" -a -d "$1" ]; then
	if have_same_device_and_inode "$VIRTUAL_ENV" "$1"; then
	    abort "%s: %s: Virtual environment activated\n" "$0" "$VIRTUAL_ENV"
	fi
    fi

    if [ -d $1 ]; then
	sync=false
    else
	sync=true
    fi

    if [ $sync = true ]; then
	upgrade_via_pip pip || true
	create_virtualenv "$@"
    fi

    if [ -r $1/bin/activate ]; then
	activate_virtualenv $1
	assert [ -n "${VIRTUAL_ENV-}" ]

	if [ "${venv_force_sync:-$sync}" = true ]; then
	    upgrade_requirements_via_pip
	fi
    elif [ -d $1 ]; then
	abort "%s: Unable to activate environment\n" "$0"
    else
	abort "%s: No virtual environment\n" "$0"
    fi
}

set_unpriv_environment() {
    home_dir="$(get_home_directory $(get_user_name))"

    if [ "$HOME" != "$home_dir" ]; then
	export HOME="$home_dir"
	cd $HOME

	if [ -r .profile ]; then
	    set +u
	    . ./.profile
	    set -u
	fi
    fi

    if ! grep_path $PATH "^$HOME/.local/bin\$"; then
	export PATH="$HOME/.local/bin:$PATH"
    fi
}

upgrade_requirements_via_pip() (
    pip=$(get_command pip)

    if [ -z "$pip" ]; then
	return 1
    fi

    printf "%s\n" "Upgrading virtual environment packages via pip"
    install_via_pip --upgrade pip || true
    printf "%s\n" "Installing virtual environment packages via pip"
    install_via_pip $(get_pip_requirements)
)

upgrade_via_pip() (
    if [ -n "${SYSTEM_PYTHON-}" ]; then
	options="-p \"$SYSTEM_PYTHON\""
    else
	options="-v \"$PYTHON_VERSIONS\""
    fi

    pip=$(eval get_command $options pip)

    if [ -z "$pip" ]; then
	return 1
    fi

    printf "%s\n" "Upgrading user packages via pip"
    install_via_pip --upgrade --user "$@"
)
