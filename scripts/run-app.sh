#!/bin/sh -eu

# run: run command within a Python 3 virtual environment
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

: ${LANG:=en_US.UTF-8}
: ${LC_ALL:=en_US.UTF-8}
export LANG LC_ALL

abort() {
    printf "$@" >&2
    exit 1
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_realpath() (
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

run_in_virtualenv() {
    pipenv=$(get_command pipenv || true)

    if [ -z "$pipenv" ]; then
	pip=$(get_command -v "$PYTHON_VERSIONS" pip || true)
    fi

    if [ -n "${source_dir-}" ]; then
	cd "$source_dir"
    fi

    if [ -n "$pipenv" ]; then
	run_via_pipenv "$@"
    elif [ -n "$pip" ]; then
	run_via_pip "$@"
    else
	abort "%s: Neither pip nor pipenv command found in PATH\n" "$0"
    fi
}

run_via_pip() {
    venv_requirements=$VENV_REQUIREMENTS
    refresh_via_pip $VENV_FILENAME

    # Export nonempty parameters only
    for var in $APP_ENV_VARS; do
	if [ -n "${var-}" ]; then
	    export $var
	fi
    done

    if [ -r .env ]; then
	printf "%s\n" "Loading .env environment variables"
	. ./.env
    fi

    "$@"
}

run_via_pipenv() {
    if ! $pipenv --venv >/dev/null 2>&1; then
	upgrade_via_pip pip pipenv || true

	if pyenv --version >/dev/null 2>&1; then
	    python=$(find_python)
	    $pipenv --python $python
	else
	    $pipenv $PIPENV_OPTS
	fi

	$pipenv sync -d
    fi

    if [ "${PIPENV_ACTIVE:-0}" -gt 0 ]; then
	"$@"
    else
	$pipenv run "$@"
    fi
}

if [ $# -eq 0 ]; then
    abort "%s: Not enough arguments\n" "$0"
fi

if [ "$(id -u)" -eq 0 ]; then
    abort "%s: Must be run as a non-privileged user\n" "$0"
fi

script_dir=$(get_realpath "$(dirname "$0")")

source_dir=$(pwd)

until [ "$source_dir" = / -o -r "$source_dir/.env" ]; do
    source_dir="$(dirname $source_dir)"
done

if [ "$source_dir" = / ]; then
    unset source_dir
fi

eval $("$script_dir/get-os-release.sh" -x)

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_baseline
run_in_virtualenv "$@"