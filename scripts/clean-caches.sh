#!/bin/sh

dirs=$(find . -type d \( -name '.venv*' -prune -o -name .pytest_cache -print -o -name __pycache__ -print \))

if [ -n "$dirs" ]; then
    /bin/rm -rf $dirs
fi
