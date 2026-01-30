#!/bin/bash
n=$1
echo -n .$n
if [ "$n" == "auto_test.li" ] ; then
    exit 0
fi
exit 1
