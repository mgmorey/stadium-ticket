# -*- Mode: Shell-script -*-

# populate-virtualenv: install requirements into virtual environment
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

sync_venv() {
    assert [ "$pip" != false ]
    printf "%s\n" "Upgrading pip"
    $pip install $pip_opts --upgrade pip
    printf "%s\n" "Installing required packages"
    $pip install $pip_opts $(printf -- "-r %s\n" ${REQUIREMENTS:-requirements.txt})
}

if [ -z "$VIRTUAL_ENV" ]; then
    abort "%s\n" "$0: Must run in active virtual environment"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must run as a non-privileged user"
fi

for pip in $PIP "$PYTHON -m pip" false; do
    if $pip >/dev/null 2>&1; then
	break
    fi
done

# Use no cache if child process of sudo
pip_opts=${SUDO_USER:+--no-cache-dir}

sync_venv
