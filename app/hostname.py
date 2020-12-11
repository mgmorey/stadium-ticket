# -*- coding: utf-8 -*-
"""Return a default value for hostname."""

import os

LOCALHOST = 'localhost'
WSL_HOST = 'WSL_HOST'


def get_hostname() -> str:
    """Return a default value for hostname."""
    return os.getenv(WSL_HOST, LOCALHOST)
