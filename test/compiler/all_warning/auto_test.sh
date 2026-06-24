#!/bin/bash
n=$1
echo -n .$n
if ! lisaac $n -q -all_warning ; then
    echo -n ERROR$n
    exit 2
fi
rm -rf ${n}.c
echo -n .
exit 1
