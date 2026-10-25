#!/bin/bash

echo "-----------------------------------------"
echo "-- LiA: Li Android - Log viewer (macOS) --"
echo "-----------------------------------------"
echo 
echo "Usage: $0 [<filter>]"
echo "Note: by default <filter>=LIA"
echo

adb shell setprop persist.log.tag V

if [ -z "$1" ]
then
    adb logcat -s LIA:V
else
    adb logcat | grep $1
fi
