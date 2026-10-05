#!/bin/bash
n=$1
echo -n .$n
if ! lisaac $n -q >& warning.new ; then
    echo -n ERROR$n
    exit 1
fi
echo -n .
if ! diff warning.new warning ; then
    echo -n ERROR$n
    exit 1
fi
rm -rf warning.new main main.c
echo -n .
exit 0
