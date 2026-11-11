#!/bin/bash
# Run with lili every test of ../test which has an expected `stdout' file.
# Usage: ./compare.sh [work_directory]  (the tests are copied there, not run in place)
here=$(cd "$(dirname "$0")" && pwd)
work=${1:-$(mktemp -d)}
mkdir -p "$work"
cp -rL "$here/../test" "$work/" 2>/dev/null
cd "$work/test" || exit 1
ok=0; ko=0; : > ../failed.txt
for out in $(find . -name stdout | sort); do
  d=$(dirname "$out")
  ( cd "$d"
    m=main.li
    [ -f main.li ] || m=$(basename "$d").li
    [ -f "$m" ] || m=$(ls *.li 2>/dev/null | head -1)
    [ -n "$m" ] || exit 3
    a=""
    [ -f args ] && a="-- $(cat args)"
    timeout 20 "$here/lili" "$m" $a > .out 2> .err < /dev/null
    sed -i -E 's#\(.*/test/#(.../test/#' .out
    cmp -s .out stdout )
  if [ $? = 0 ]; then ok=$((ok+1)); else ko=$((ko+1)); echo "$d" >> ../failed.txt; fi
done
echo "ok=$ok ko=$ko"
