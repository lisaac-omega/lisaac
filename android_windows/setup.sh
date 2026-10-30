#!/bin/bash
# LiA (Windows) : verification des outils, telechargement de ceux qui manquent.
# Appele par make.lip (`lisaac -target android') ; equivalent de misc/android.sh.
# Usage: bash setup.sh
# Les outils du SDK Android et Java sont installes dans `android_windows/sdk/'
# (sans droits administrateur) ; clang, lld et zip viennent de MSYS2 (pacman).
set -euo pipefail
. "$(cygpath -u "$0" | sed 's,/[^/]*$,,')/env.sh"

BUILD_TOOLS_ZIP="build-tools_r36.1_windows.zip"
BUILD_TOOLS_SHA1="95f048ae758dad90617975fe3f787f038b03338c"
PLATFORM_TOOLS_ZIP="platform-tools-latest-windows.zip"
GOOGLE_URL="https://dl.google.com/android/repository"
JRE_URL="https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse"

# $1 = url, $2 = repertoire d'arrivee (dans $SDK), $3 = sha1 attendu (optionnel)
download_unzip() {
    local zip="$SDK/download.zip"
    mkdir -p "$SDK/$2"
    echo "Wait download $1 ..."
    curl -fL --progress-bar -o "$zip" "$1"
    if [ -n "${3:-}" ] && [ "$(sha1sum "$zip" | cut -d' ' -f1)" != "$3" ]; then
        rm -f "$zip"
        echo "Bad checksum for $1"
        exit 1
    fi
    unzip -q -o "$zip" -d "$SDK/$2"
    rm -f "$zip"
}

# 1) clang, lld, zip : paquets MSYS2.
pkgs=""
[ -n "$CLANG" ] || pkgs="$pkgs mingw-w64-x86_64-clang"
[ -n "$LLD" ]   || pkgs="$pkgs mingw-w64-x86_64-lld"
command -v zip >/dev/null 2>&1 || pkgs="$pkgs zip"
if [ -n "$pkgs" ]; then
    echo "Installing MSYS2 packages:$pkgs"
    if ! pacman -S --noconfirm --needed $pkgs; then
        echo "lisaac -target android (Windows) requires, in a MSYS2 shell:"
        echo "    pacman -Syu"
        echo "    pacman -S$pkgs"
        echo "See $LI/ANDROID_WINDOWS.txt"
        exit 1
    fi
fi

# 2) aapt2, zipalign (build-tools) et adb (platform-tools).
if [ -z "$AAPT2" ] || [ -z "$ZIPALIGN" ]; then
    download_unzip "$GOOGLE_URL/$BUILD_TOOLS_ZIP" build-tools "$BUILD_TOOLS_SHA1"
fi
if [ -z "$ADB" ]; then
    download_unzip "$GOOGLE_URL/$PLATFORM_TOOLS_ZIP" .
fi

# 3) Java (pour apksigner).
if [ -z "$JAVA" ]; then
    download_unzip "$JRE_URL" jre
fi

# 4) Fichiers communs `lisaac/android' (sysroot, android.jar, ...).
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

# Verification finale.
. "$LIAW/env.sh"
missing=0
for t in CLANG LLD AAPT2 ZIPALIGN ADB JAVA; do
    if [ -z "${!t}" ]; then
        echo "lisaac -target android (Windows): $t not found."
        missing=1
    fi
done
if [ $missing -ne 0 ]; then
    echo "See $LI/ANDROID_WINDOWS.txt"
    exit 1
fi
