# -*- Mode: Shell-script -*-

# common-parameters.sh: define commonly used parameters
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

ENV_VERBOSE=false

PIP_INSTALL_QUIET=false
PIP_INSTALL_VERBOSE=false
PIP_UPGRADE_USER=true
PIP_UPGRADE_VENV=true
PYENV_INSTALL_VERBOSE=false

PYPI_UTILITIES="pipenv pip"
PYTHON_VERSIONS="3.7 3.6 3.5 3"

VENV_REQUIREMENTS=requirements*.txt
VENV_UTILITIES="pyvenv virtualenv"
VENV_VERBOSE=false
