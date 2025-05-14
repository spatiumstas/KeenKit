#!/bin/sh

REPO="KeenKit"
SCRIPT="keenkit.sh"
TMP_DIR="/tmp"
OPT_DIR="/opt"

if ! opkg list-installed | grep -q "^curl" || ! opkg list-installed | grep -q "^tar"; then
  opkg update && opkg install curl tar
fi

curl -L -s "https://raw.githubusercontent.com/spatiumstas/$REPO/main/$SCRIPT" --output $TMP_DIR/$SCRIPT
mv "$TMP_DIR/$SCRIPT" "$OPT_DIR/$SCRIPT"
chmod +x $OPT_DIR/$SCRIPT
cd $OPT_DIR/bin
ln -sf $OPT_DIR/$SCRIPT $OPT_DIR/bin/keenkit
$OPT_DIR/$SCRIPT
