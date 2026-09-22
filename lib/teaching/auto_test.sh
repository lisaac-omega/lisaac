#!/bin/bash
n=$1
echo -n .$n
if [ "$n" == "tortue.li" ] ; then
    # ok
    exit 0
else
    echo -n '.ERROR main inside ?'
    exit 2
fi
exit 1
