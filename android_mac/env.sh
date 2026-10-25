#!/bin/bash
# LiA (macOS) : environnement commun a `setup.sh' et `run.sh'.
# A sourcer : `. android_mac/env.sh'.
# Voir lisaac/ANDROID_MAC.txt pour l'installation des outils.

LI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIA="$LI/android"          # Fichiers communs Linux/macOS (sysroot, android.jar, tools, ...)
LIAM="$LI/android_mac"     # Scripts specifiques macOS
MISC="$LI/misc"
TOOL="$LIA/tools"
SYSROOT="$LIA/sysroot"
SYSLIB="$SYSROOT/usr/lib/aarch64-linux-android/24"
BUILTINS="$LIA/lib/clang/17/lib/linux/libclang_rt.builtins-aarch64-android.a"

# Compilateur C : clang d'Apple (Xcode Command Line Tools) par defaut.
CLANG="${CLANG:-/usr/bin/clang}"

# Recherche d'un outil du SDK Android (aapt2, zipalign) :
# d'abord le PATH, puis le build-tools le plus recent des SDK connus.
find_sdk_tool() {
    local t d bt
    if t="$(command -v "$1" 2>/dev/null)"; then
        echo "$t"
        return 0
    fi
    for d in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
             /opt/homebrew/share/android-commandlinetools \
             /usr/local/share/android-commandlinetools \
             "$HOME/Library/Android/sdk"; do
        [ -n "$d" ] && [ -d "$d/build-tools" ] || continue
        bt="$(ls -d "$d"/build-tools/*/ 2>/dev/null | sort -V | tail -1)"
        if [ -n "$bt" ] && [ -x "$bt$1" ]; then
            echo "$bt$1"
            return 0
        fi
    done
    return 1
}

AAPT2="$(find_sdk_tool aapt2 || true)"
ZIPALIGN="$(find_sdk_tool zipalign || true)"
LLD="$(command -v ld.lld 2>/dev/null || true)"

# Java : JAVA_HOME, puis le PATH (Temurin, ...), puis l'openjdk de Homebrew
# (keg-only, donc absent du PATH par defaut).
JAVA=""
for j in "${JAVA_HOME:+$JAVA_HOME/bin/java}" java \
         /opt/homebrew/opt/openjdk/bin/java /usr/local/opt/openjdk/bin/java; do
    if [ -n "$j" ] && "$j" -version >/dev/null 2>&1; then
        JAVA="$(command -v "$j")"
        break
    fi
done
