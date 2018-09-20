#!/bin/sh

if [ ! $1 ]; then
       cmd='help'
else
       cmd=$1
fi

if [ $cmd != "help" ];then
    ../skynet/3rd/lua/lua ./$cmd
else
    echo "parm1 is client test lua"
fi
