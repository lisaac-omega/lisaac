#!/bin/bash
# LiA (Windows) : affiche les logs de l'application (adb logcat).
. "$(cygpath -u "$0" | sed 's,/[^/]*$,,')/env.sh"

echo "-------------------------------------------"
echo "-- LiA: Li Android - Log viewer (Windows) --"
echo "-------------------------------------------"
echo 
echo "Usage: $0 [<filter>]"
echo "Note: by default <filter>=LIA"
echo

"$ADB" shell setprop persist.log.tag V

if [ -z "$1" ]
then
    "$ADB" logcat -s LIA:V
else
    "$ADB" logcat | grep $1
fi
