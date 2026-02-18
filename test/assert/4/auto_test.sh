#!/bin/bash
n=$1
echo -n .$n
if [ "$n" == "main.li" ] ; then
    lisaac main -q
    ./main 1> stdout.new 2> stderr.new
    if diff stdout stdout.new ; then
	echo -n .
	rm stdout.new
	if diff stderr stderr.new ; then
	    echo -n .
	    rm stderr.new main main.c
	    exit 0
	else
	    echo -n ERROR$n
	    exit 1
	fi
    else
	echo -n ERROR$n
	exit 1
    fi
fi
exit 1
