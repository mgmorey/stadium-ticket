#!/bin/sh

dirs=$(find . -type d \( -name '.venv*' -prune -o -name '*py*cache*' -print \))

if [ -n "$dirs" ]; then
    /bin/rm -rf $dirs
fi
