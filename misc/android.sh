#!/bin/bash
set -euo pipefail
echo $1android
if ! command -v adb >/dev/null 2>&1; then
    echo "lisaac -target android requires adb:"
    echo sudo apt install adb
    exit 1
fi
if [ ! -d "$1android" ]; then
    version=$(lisaac -version | grep Version | grep -oP '\d+\.\d+')
    zipandroid="android_${version}.zip"
    url="https://lisaac.org/downloads/${zipandroid}"
    pushd "$1" >/dev/null
    echo Wait download ${url} ...
    wget -q --show-progress -O ${zipandroid} ${url}
    unzip -q ${zipandroid}
    popd >/dev/null    
fi    

