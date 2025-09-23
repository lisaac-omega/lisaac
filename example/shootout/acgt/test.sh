#! /bin/bash

echo Launch Program
./acgt > test.out
echo Test md5sum
#echo $PWD
md5sum	-c test.md5
rm test.out


