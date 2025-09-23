#!C:\msys64\usr\bin\bash.exe
VERBOSE=false
MISC=$1/misc
if [ ! -d assets ]; then
    if $VERBOSE; then
	echo "Creating default assets directory:"
	echo cp -r $MISC/assets .
    fi
    cp -r $MISC/assets .
fi
