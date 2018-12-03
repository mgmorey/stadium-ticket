#!/bin/sh -eux

tmpfile="tmp$$"
trap "/bin/rm -f $tmpfile ${tmpfile}~" INT QUIT TERM

if [ -r .env ]; then
    cp -f .env .env~
    cp -f .env $tmpfile
else
    cp .env-template $tmpfile
fi

if $EDITOR $tmpfile; then
   mv -f $tmpfile .env
fi
