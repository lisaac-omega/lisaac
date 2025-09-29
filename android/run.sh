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
LIA="$LI/android"
MISC="$LI/misc"
TOOL="$LIA/tools"

if $VERBOSE; then
    echo "I] Create android interface."
fi
if [ ! -d "lia" ]; then
    if $VERBOSE; then
        echo "    Copy default icons."
    fi  
    mkdir -p android/lib/arm64-v8a    
    cp -r $TOOL/res android/.
    $MISC/new_assets.sh $LI
    if $VERBOSE; then
        echo "    Copy & update \`AndroidManifest.xml' ..."
    fi
    cp $TOOL/AndroidManifest.xml android/.
    sed -i "s/!MY_PROJECT!/$1/" android/AndroidManifest.xml
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
cmd="$LIA/clang -fPIC --sysroot $LIA/sysroot -c $TOOL/android_native_app_glue.c -O2"
echo $cmd; $cmd

if $VERBOSE; then
    echo "  --> Compiling \`$1' ..."
fi
cmd="$LIA/clang -fPIC --sysroot $LIA/sysroot -c $1.c $INC $OPS -O2"
echo $cmd; $cmd

if $VERBOSE; then
    echo "  --> Linking..."
fi

cmd="$LIA/clang -shared android_native_app_glue.o $1.o -o lib$1.so -landroid -lEGL -lGLESv3 -lcamera2ndk -lmediandk -llog -lm -ldl -lc -L . $LIB -u ANativeActivity_onCreate -s"
echo $cmd; $cmd

if $VERBOSE; then
    echo " 3) Making APK..."
    echo "  --> Create APK empty..."
fi
#cmd="$BINPATH/28/aapt2 package --debug-mode -f -F $1.unaligned.apk -M lia/AndroidManifest.xml -S lia/res -A lia/assets -I $BINPATH/android.jar"
cmd="$LIA/aapt2 compile --dir android/res -o android/compiled.zip"
echo $cmd; $cmd;

cmd="$LIA/aapt2 link -o "$1.unaligned.apk" \
  --manifest android/AndroidManifest.xml \
  -I "$LIA/android.jar" \
  -R android/compiled.zip \
  -A android/assets"
echo $cmd; $cmd;

if $VERBOSE; then
    echo "  --> Add \`lib$1.so' in APK ..."
fi

cd android
mv ../lib$1.so lib/arm64-v8a/.
cmd="zip -u ../$1.unaligned.apk lib/arm64-v8a/lib$1.so"
echo $cmd; $cmd;
cd ..

if $VERBOSE; then
    echo "  --> Aligning APK..."
fi

cmd="$LIA/zipalign -f 4 $1.unaligned.apk $1.apk"
echo $cmd; $cmd;

#if $VERBOSE; then
#    echo "  --> Add \`classes.dex' in APK..."
#fi

#$TOOL/dx --dex --output=classes.dex $TOOL/uiautomator.jar

#cmd="aapt add $1.unaligned.apk classes.dex"
#echo $cmd
#if $VERBOSE; then
#    $cmd 
#else
#    $cmd >& /dev/null
#fi
if $VERBOSE; then
    echo "  --> Signing APK..."
fi    
java -jar $LIA/apksigner.jar sign --min-sdk-version 24 --ks $TOOL/mykey.keystore $1.apk < $TOOL/passwd.txt >/dev/null
#echo $cmd; $cmd;

if $VERBOSE; then
    echo " 4) Cleaning..."
fi
rm *.o $1.unaligned.apk $1.apk.idsig
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
    echo "Note: consider using \`lisaac/android/log.sh' to view output/debug info."
fi
