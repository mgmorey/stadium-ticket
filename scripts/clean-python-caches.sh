#!/bin/sh

dirs=$(find . -type d \( -name '.venv*' -prune -o -name '__py*' -print \))

if [ -n "$dirs" ]; then
    /bin/rm -rf $dirs
fi
