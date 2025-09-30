#!/bin/bash
VERBOSE=false
MISC=$1misc
DEST="$(dirname -- "${2}")"
if [ ! -d $DEST/assets ]; then
    if $VERBOSE; then
	echo "Creating default assets directory:"
	echo cp -r $MISC/assets $DEST
    fi
    cp -r $MISC/assets $DEST
fi
