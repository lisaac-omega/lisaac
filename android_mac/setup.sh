#!/bin/bash
# LiA (macOS) : verification des outils et telechargement de `lisaac/android'.
# Appele par make.lip (`lisaac -target android') ; equivalent de misc/android.sh.
# Usage: setup.sh <lisaac_dir/>
set -euo pipefail
. "$(dirname "$0")/env.sh"

missing=0
need() {
    # $1 = nom, $2 = chemin trouve (vide si absent), $3 = installation
    if [ -z "$2" ]; then
        echo "lisaac -target android (macOS) requires $1:"
        echo "    $3"
        missing=1
    fi
}
need adb      "$(command -v adb 2>/dev/null || true)" "brew install --cask android-platform-tools"
need ld.lld   "$LLD"                                  "brew install lld"
need clang    "$([ -x "$CLANG" ] && echo "$CLANG")"   "xcode-select --install"
need java     "$JAVA"     "brew install openjdk  (or: brew install --cask temurin)"
need aapt2    "$AAPT2"    "sdkmanager \"build-tools;35.0.0\"  (after: brew install --cask android-commandlinetools)"
need zipalign "$ZIPALIGN" "sdkmanager \"build-tools;35.0.0\"  (after: brew install --cask android-commandlinetools)"
if [ $missing -ne 0 ]; then
    echo "See $LI/ANDROID_MAC.txt"
    exit 1
fi

if [ ! -d "$LIA" ]; then
    version=$("$LI/bin/lisaac" -version | grep '^Version' | sed -E 's/^[^0-9]*([0-9]+\.[0-9]+).*/\1/')
    zipandroid="android_${version}.zip"
    url="https://lisaac.org/downloads/${zipandroid}"
    pushd "$LI" >/dev/null
    echo Wait download ${url} ...
    curl -fL --progress-bar -o ${zipandroid} ${url}
    unzip -q ${zipandroid}
    popd >/dev/null
fi
