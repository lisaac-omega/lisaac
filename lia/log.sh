#!/bin/bash

echo "-----------------------------------"
echo "-- LiA: Li Android - Log viewer  --"
echo "-----------------------------------"
echo 
echo "Usage: $0 [<filter>]"
echo "Note: by default <filter>=LIA"
echo

if [ -z "$1" ]
then
    adb logcat | grep "LIA"
else
    adb logcat | grep $1
fi
