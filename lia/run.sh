#!/bin/bash
VERBOSE=true
if $VERBOSE; then
    echo "---------------------------------------"
    echo "-- LiA: Lisaac Android - APK Builder --"
    echo "---------------------------------------"
    echo
fi
if [ -z "$1" ]; then
    echo
    echo "Usage: $0 <name_project>"
    echo
    exit 1
fi
set -e
LI=`which lisaac`
LI="${LI%/bin/lisaac}"
LIA="$LI/lia"
MISC="$LI/misc"
TOOL="$LIA/tool"
OPS=" -I$LI/deps_lib -Wno-invalid-source-encoding -D_GNU_SOURCE -Wno-address-of-packed-member -U_FORTIFY_SOURCE -Wno-strict-aliasing -Wno-parentheses-equality -Wstrict-overflow=0"
ZIPA="$LIA/android-sdk/build-tools/debian/zipalign"
if $VERBOSE; then
    echo "Create android interface."
fi
if [ ! -d "lia" ]; then
    if $VERBOSE; then
        echo "Copy default icons:"
    fi  
    mkdir -p lia/lib/arm64-v8a
    mkdir -p lia/lib/armeabi-v7a
    if [ -z "$2" ]; then
	cp -r $LIA/tool/res lia/.
    else
	cp -r $LIA/tool/res_li lia/res
    fi
    $MISC/new_assets.sh
    if $VERBOSE; then
        echo " 2) Copy & update \`AndroidManifest.xml' ..."
    fi
    cp $LIA/tool/AndroidManifest.xml lia/.
    sed -i "s/!MY_PROJECT!/$1/" lia/AndroidManifest.xml
fi
rm -rf lia/assets
cp -prf assets lia
# Begin Just for Elit
if [ -f "tool/update_android.sh" ]; then
    tool/update_android.sh
fi
# End Just for Elit
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
rm -rf lia/lib/arm64-v8a/*
rm -rf lia/lib/armeabi-v7a/*

if $VERBOSE; then
    echo " 2) Compiling for ARM 32bits... SKIP"
fi
#BINPATH="$LIA/android-ndk-r18/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"

#INC="-I $LIA/android-ndk-r18/sysroot/usr/include -I $LIA/android-ndk-r18/sysroot/usr/include/arm-linux-androideabi -I $LIA/tool"

#ARCH="$TOOL/armeabi-v7a"
#SO="lia/lib/armeabi-v7a"

#if $VERBOSE; then
#    echo "  --> Compiling \`android_native_glue'..."
#fi
#$BINPATH/arm-linux-androideabi-gcc -c $TOOL/android_native_app_glue.c -O2 $INC

#if $VERBOSE; then
#    echo "  --> Compiling \`$1' ..."
#fi
#$BINPATH/arm-linux-androideabi-gcc -c $1.c $INC $OPS

#if $VERBOSE; then
#    echo "  --> Linking..."
#fi
#LIB="-L $LIA/android-ndk-r18/platforms/android-19/arch-arm/usr/lib"

#$BINPATH/arm-linux-androideabi-ld -shared $LIB/crtbegin_so.o $LIB/crtend_so.o $1.o android_native_app_glue.o -o $SO/lib$1.so -landroid -lEGL -lGLESv3  -llog -lm -ldl -lc -L . $LIB -u ANativeActivity_onCreate -s

if $VERBOSE; then
    echo " 3) Compiling for ARM 64bits..."
fi
BINPATH="$LIA/android-ndk-r18/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin"

INC="-I $LIA/android-ndk-r18/sysroot/usr/include -I $LIA/android-ndk-r18/sysroot/usr/include/aarch64-linux-android -I $LIA/tool"

ARCH="$TOOL/arm64-v8a"
SO="lia/lib/arm64-v8a"

if $VERBOSE; then
    echo "  --> Compiling \`android_native_glue'..."
fi
$BINPATH/aarch64-linux-android-gcc -c $TOOL/android_native_app_glue.c -O2 $INC 

if $VERBOSE; then
    echo "  --> Compiling \`$1' ..."
fi
$BINPATH/aarch64-linux-android-gcc -c $1.c $INC $OPS -O2 

if $VERBOSE; then
    echo "  --> Linking..."
fi
LIB="-L $LIA/android-ndk-r18/platforms/android-28/arch-arm64/usr/lib"

cmd="$BINPATH/aarch64-linux-android-ld -shared android_native_app_glue.o $1.o -o $SO/lib$1.so -landroid -lEGL -lGLESv3 -lcamera2ndk -lmediandk -llog -lm -ldl -lc -L . $LIB -u ANativeActivity_onCreate -s"
echo $cmd; $cmd

if $VERBOSE; then
    echo " 4) Making APK...$LIB/crtbegin_so.o $LIB/crtend_so.o $LIB/crtbegin_dynamic.o $LIB/crtend_android.o"
    echo "  --> Create APK empty..."
fi
cmd="aapt package --debug-mode -f -F $1.unaligned.apk -M lia/AndroidManifest.xml -S lia/res -A lia/assets -I $TOOL/android.jar"
echo $cmd; $cmd;
if $VERBOSE; then
    echo "  --> Add \`lib$1.so' in APK ..."
fi
mv $1.unaligned.apk $1.unaligned.zip
cd lia
#zip -q ../$1.unaligned.zip lib/armeabi-v7a/lib$1.so SKIP 32BIT
zip -q ../$1.unaligned.zip lib/arm64-v8a/lib$1.so
cd ..
mv $1.unaligned.zip $1.unaligned.apk

if $VERBOSE; then
    echo "  --> Add \`classes.dex' in APK..."
fi
$TOOL/dx --dex --output=classes.dex $TOOL/uiautomator.jar

cmd="aapt add $1.unaligned.apk classes.dex"
echo $cmd
if $VERBOSE; then
    $cmd 
else
    $cmd >& /dev/null
fi
if $VERBOSE; then
    echo "  --> Aligning APK..."
fi
$ZIPA -f 4 $1.unaligned.apk $1.apk

if $VERBOSE; then
    echo "  --> Signing APK..."
    java -jar $TOOL/apksigner.jar sign --min-sdk-version 24 --ks $TOOL/mykey.keystore $1.apk < $TOOL/passwd.txt
else
    java -jar $TOOL/apksigner.jar sign --min-sdk-version 24 --ks $TOOL/mykey.keystore $1.apk < $TOOL/passwd.txt >/dev/null
fi
if $VERBOSE; then
    echo " 5) Cleaning..."
fi
rm *.o classes.dex $1.unaligned.apk
if $VERBOSE; then
    echo
    echo "Done."
    echo
fi
if $VERBOSE; then
    echo "III] Launching on your target..."
fi
cmd="adb install -r $1.apk"
if ! $cmd; then
    echo "Make sure your android device is pluged to this computer"
    echo "Also make sure that developper mode is enabled on your android device."
    echo "Also make sure that USB debug is enabled on your android device."
    exit 1
fi
if $VERBOSE; then
    echo "Note: consider using \`lisaac/lia/log.sh' to view output/debug info."
fi
#adb push lib /sdcard/lib
