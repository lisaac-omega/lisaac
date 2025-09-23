rm -rf web
mkdir web
cp -r assets web/.
if [ -f tool/update_web.sh ]; then
    tool/update_web.sh
fi
