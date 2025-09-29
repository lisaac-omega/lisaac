#!/bin/bash
VERBOSE=false
LI=`which lisaac`
LI="${LI%/bin/lisaac}"
cd ${LI} || exit 1
if [ ! "$1" ]; then
    echo "Updating ${LI}/libx ..."
    cd ${LI}/src || exit 1
    echo pwd $(pwd)
    cmd="lisaac lidoc -without_source "; echo $cmd;
    if ! $cmd; then
	exit 1
    fi
fi
cd ${LI} || exit 1
echo pwd $(pwd)
find ./libx -name '*.li' -exec rm -f {} \;
find ./libx -name '*.lix' -exec rm -f {} \;
for f in $(find ./lib -name '*.li')
do
    # Ben je te laisse voir ces cas particulier qui passent pas dans lidoc: 
    skip=false
    for pb in \
	draw/TARGET/web/keyboard.li \
	draw/TARGET/web/mevent.li \
	draw/TARGET/web/paper.li \
	draw/TARGET/android/keyboard.li \
	draw/TARGET/android/paper.li \
	file_system/TARGET/windows/file_unix.li \
	file_system/TARGET/windows/system_io.li \
	file_system/TARGET/windows/entry_unix.li \
	file_system/TARGET/windows/directory_unix.li \
	file_system/TARGET/windows/file_system.li \
	file_system/TARGET/windows/target.li \
	file_system/TARGET/web/file_unix.li \
	file_system/TARGET/web/target.li \
	file_system/TARGET/web/system_io.li \
	file_system/TARGET/web/entry_unix.li \
	file_system/TARGET/web/directory_unix.li \
	file_system/TARGET/android/file_unix.li \
	file_system/TARGET/android/target.li \
	file_system/TARGET/android/system_io.li \
	file_system/TARGET/android/entry_unix.li \
	file_system/TARGET/android/directory_unix.li \
	file_system/TARGET/arduino/system_io.li \
	finitos
    do
	if [ $f == ./lib/$pb ]; then
	    skip=true
	fi
    done
    $skip && continue
    f2=${f#./lib/}
    f2="./libx/${f2}"
    cmd="cp -prf $f $f2";
    if ! $cmd; then
	echo pwd $(pwd)
	echo $cmd
	exit 1
    fi
done
cd ${LI}/libx || exit 1
echo pwd $(pwd)
cmd="${LI}/src/lidoc . -code -private -format belinda -output ../doc/html";
echo $cmd;$cmd
cd ${LI} || exit 1
#for f in $(find ./libx -name '*.li')
#do
#    if [ ! -f ${f}x ]; then
#	echo No "${f}x" for "${f}"
#	exit 1
#    fi
#done
echo "Updating ${LI}/libx done."
cd ${LI} || exit 1
find ./libx -name '*.li' -exec rm -f {} \;
exit 0
