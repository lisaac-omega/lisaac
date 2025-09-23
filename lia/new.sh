#!/bin/bash

echo "---------------------------------------"
echo "-- LiA: Lisaac Android - New project --"
echo "---------------------------------------"

if [ -z "$1" ]
then
    echo
    echo "Usage: $0 <name_project>"
    echo
    exit
fi

echo "1) Create \`project/$1' ..."
mkdir -p project/$1/apk
mkdir -p project/$1/src
mkdir -p project/$1/lib/arm64-v8a
mkdir -p project/$1/lib/armeabi-v7a

echo "2) Copy icones by default in \`project/$1/res' ..."
cp -r tool/res project/$1/.

echo "3) Copy & update \`AndroidManifest.xml' ..."
cp tool/AndroidManifest.xml project/$1/.
sed -i "s/!MY_PROJECT!/$1/" project/$1/AndroidManifest.xml

echo
echo "Done."
echo
