#!/bin/bash
# LiA (Windows) : construction et installation d'un APK.
# Equivalent Windows de android/run.sh, appele par make.lip (`lisaac -target android').
# Reutilise les fichiers independants de la plateforme de `lisaac/android'
# (sysroot, android.jar, apksigner.jar, tools/) et les outils Windows (MSYS2)
# decrits dans lisaac/ANDROID_WINDOWS.txt.
VERBOSE=true
if $VERBOSE; then
    echo "-------------------------------------------------"
    echo "-- LiA: Lisaac Android - APK Builder (Windows) --"
    echo "-------------------------------------------------"
    echo
fi
if [ -z "$1" ]; then
    echo
    echo "Usage: $0 <name_project>"
    echo
    exit 1
fi
set -e
. "$(cygpath -u "$0" | sed 's;/[^/]*$;;')/env.sh"
CC="$CLANG --target=aarch64-linux-android24 --sysroot $SYSROOT"

if $VERBOSE; then
    echo "I] Create android interface."
fi
if [ ! -d "android" ]; then
    if $VERBOSE; then
        echo "    Copy default icons."
    fi
    mkdir -p android/lib/arm64-v8a
    cp -r $TOOL/res android/.
    if $VERBOSE; then
        echo "    Copy & update \`AndroidManifest.xml' ..."
    fi
    sed "s/!MY_PROJECT!/$1/" $TOOL/AndroidManifest.xml > android/AndroidManifest.xml
fi
if [ ! -d "assets" ]; then
    if [ ! -x "$MISC/new_assets" ]; then
        if $VERBOSE; then
            echo "    Compiling \`misc/new_assets.li' ..."
        fi
        (cd "$MISC" && "$LI/bin/lisaac" new_assets -q)
    fi
    if $VERBOSE; then
        echo "    Creating default assets directory."
    fi
    "$MISC/new_assets" "$LI/" "$1"
fi
rm -rf android/assets
cp -prf assets android

if $VERBOSE; then
    echo
    echo "Done."
    echo
fi

if $VERBOSE; then
    echo "II] APK builder."
    echo " 1) Cleaning..."
fi
rm -rf *.apk
rm -rf android/lib/arm64-v8a/*

if $VERBOSE; then
    echo " 2) Compiling for ARM 64bits..."
fi

INC="-I $LI/deps_lib -I $TOOL"

if $VERBOSE; then
    echo "  --> Compiling \`android_native_glue'..."
fi
cmd="$CC -fPIC -c $TOOL/android_native_app_glue.c -O2"
echo $cmd; $cmd

if $VERBOSE; then
    echo "  --> Compiling \`$1' ..."
fi
cmd="$CC -fPIC -c $1.c $INC $OPS -O2 -Wno-unused-value"
echo $cmd; $cmd

if $VERBOSE; then
    echo "  --> Linking..."
fi
# Le clang de MSYS2 ne fournit pas le runtime Android : on donne explicitement
# crtbegin/crtend et les builtins de compiler-rt pris dans `lisaac/android'.
cmd="$CC -shared -nostdlib --ld-path=$LLD $SYSLIB/crtbegin_so.o android_native_app_glue.o $1.o -o lib$1.so -landroid -lEGL -lGLESv3 -lcamera2ndk -lmediandk -llog -lm -ldl -lc $BUILTINS $SYSLIB/crtend_so.o -L . $LIB -u ANativeActivity_onCreate -s"
echo $cmd; $cmd

if $VERBOSE; then
    echo " 3) Making APK..."
    echo "  --> Create APK empty..."
fi
cmd="$AAPT2 compile --dir android/res -o android/compiled.zip"
echo $cmd; $cmd;

cmd="$AAPT2 link -o $1.unaligned.apk \
  --manifest android/AndroidManifest.xml \
  -I $LIA/android.jar \
  -R android/compiled.zip"
echo $cmd; $cmd;

if $VERBOSE; then
    echo "  --> Add \`assets' and \`lib$1.so' in APK ..."
fi

cd android
mv ../lib$1.so lib/arm64-v8a/.
# Sous Windows, `aapt2 link -A' ecrit les sous-repertoires des assets avec `\'
# (illisibles sur Android) : on les ajoute avec zip, sans compresser les
# medias (meme liste que aapt).
NOCOMP=".png:.jpg:.jpeg:.gif:.webp:.wav:.mp2:.mp3:.ogg:.aac:.mpg:.mpeg:.mid:.midi:.smf:.jet:.rtttl:.imy:.xmf:.mp4:.m4a:.m4v:.3gp:.3gpp:.3g2:.3gpp2:.amr:.awb:.wma:.wmv:.webm:.mkv"
if [ -n "$(ls -A assets)" ]; then
    cmd="zip -q -r -u -n $NOCOMP ../$1.unaligned.apk assets"
    echo $cmd; $cmd;
fi
cmd="zip -u ../$1.unaligned.apk lib/arm64-v8a/lib$1.so"
echo $cmd; $cmd;
cd ..

if $VERBOSE; then
    echo "  --> Aligning APK..."
fi

cmd="$ZIPALIGN -f 4 $1.unaligned.apk $1.apk"
echo $cmd; $cmd;

if $VERBOSE; then
    echo "  --> Signing APK..."
fi
$JAVA -jar $LIA/apksigner.jar sign --min-sdk-version 24 --ks $TOOL/mykey.keystore $1.apk < $TOOL/passwd.txt >/dev/null

if $VERBOSE; then
    echo " 4) Cleaning..."
fi
rm -f *.o $1.unaligned.apk $1.apk.idsig
if $VERBOSE; then
    echo
    echo "Done."
    echo
fi
if $VERBOSE; then
    echo "III] Launching on your target..."
fi
cmd="$ADB install -r $1.apk"
if ! $cmd; then
    echo "Make sure your android device is pluged to this computer"
    echo "Also make sure that developper mode is enabled on your android device."
    echo "Also make sure that USB debug is enabled on your android device."
    exit 1
fi
if $VERBOSE; then
    echo "Note: consider using \`lisaac/android_windows/log.sh' to view output/debug info."
fi
