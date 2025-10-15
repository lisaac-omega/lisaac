#!/bin/bash
# In case of trouble, add the --verbose option.
if [ ! -f "./install.sh" ]; then
    echo 'Run this script from the "lisaac" directory.'
    echo 'Change to the "lisaac" directory and try again.'
    exit 1
fi
gcc build_lisaac.c -o build_lisaac
./build_lisaac $*
