#!/bin/bash
# LiA (Windows) : environnement commun a `setup.sh', `run.sh' et `log.sh'.
# A sourcer : `. android_windows/env.sh'. Necessite le bash de MSYS2.
# Voir lisaac/ANDROID_WINDOWS.txt pour l'installation des outils.

# Appele depuis cmd.exe (lisaac), $0 peut etre un chemin Windows (C:\...).
LIAW="$(cygpath -u "${BASH_SOURCE[0]}")"
LIAW="$(cd "${LIAW%/*}" && pwd)"   # Scripts specifiques Windows
LI="${LIAW%/*}"
LIA="$LI/android"          # Fichiers communs Linux/macOS/Windows (sysroot, android.jar, tools, ...)
MISC="$LI/misc"
TOOL="$LIA/tools"
SYSROOT="$LIA/sysroot"
SYSLIB="$SYSROOT/usr/lib/aarch64-linux-android/24"
BUILTINS="$LIA/lib/clang/17/lib/linux/libclang_rt.builtins-aarch64-android.a"
SDK="$LIAW/sdk"            # Outils telecharges par `setup.sh' (build-tools, platform-tools, jre)

# Compilateur C et editeur de liens : clang et lld de MSYS2 (mingw64).
PATH="/mingw64/bin:/usr/bin:$PATH"
CLANG="${CLANG:-$(command -v clang 2>/dev/null || true)}"
LLD="$(command -v ld.lld 2>/dev/null || true)"

# Recherche d'un outil du SDK Android (aapt2, zipalign, adb) :
# d'abord le PATH, puis les SDK connus (le build-tools le plus recent).
# $1 = outil, $2 = sous-repertoire (build-tools ou platform-tools)
find_sdk_tool() {
    local t d bt
    if t="$(command -v "$1" 2>/dev/null)"; then
        echo "$t"
        return 0
    fi
    for d in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
             "${LOCALAPPDATA:+$(cygpath -u "$LOCALAPPDATA")/Android/Sdk}" \
             "$SDK"; do
        [ -n "$d" ] && [ -d "$d/$2" ] || continue
        if [ "$2" = "build-tools" ]; then
            bt="$(ls -d "$d"/build-tools/*/ 2>/dev/null | sort -V | tail -1)"
        else
            bt="$d/$2/"
        fi
        if [ -n "$bt" ] && [ -x "$bt$1.exe" ]; then
            echo "$bt$1.exe"
            return 0
        fi
    done
    return 1
}

AAPT2="$(find_sdk_tool aapt2 build-tools || true)"
ZIPALIGN="$(find_sdk_tool zipalign build-tools || true)"
ADB="$(find_sdk_tool adb platform-tools || true)"

# Java : JAVA_HOME, puis le PATH, puis le jre telecharge par `setup.sh'.
JAVA=""
for j in "${JAVA_HOME:+$(cygpath -u "$JAVA_HOME")/bin/java}" java \
         "$(ls -d "$SDK"/jre/*/bin/java.exe 2>/dev/null | tail -1)"; do
    if [ -n "$j" ] && "$j" -version >/dev/null 2>&1; then
        JAVA="$(command -v "$j")"
        break
    fi
done
