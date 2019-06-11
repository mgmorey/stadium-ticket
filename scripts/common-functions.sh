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
	abort "%s\n" "No Python interpreter found"
    fi

    printf "%s\n" "$python"
)

find_system_python() (
    for version in $PYTHON_VERSIONS; do
	for prefix in /usr /usr/local; do
	    python_dir=$prefix/bin

	    if [ -d $python_dir ]; then
		python=$python_dir/python$version

		if [ -x $python ]; then
		    if $python --version >/dev/null 2>&1; then
			printf "%s\n" "$python"
			return 0
		    fi
		fi
	    fi
	done
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
    assert [ $# -le 1 ]

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
