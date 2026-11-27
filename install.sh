#!/bin/sh

REPO="KeenKit"
SCRIPT="keenkit.sh"
TMP_DIR="/tmp"
OPT_DIR="/opt"
BRANCH="main"

print_message() {
  local message="$1"
  local color="${2:-$NC}"
  local border=$(printf '%0.s-' $(seq 1 $((${#message} + 2))))
  printf '%b\n+%s+\n| %s |\n+%s+\n%b\n' "$color" "$border" "$message" "$border" "$NC"
}

packages_checker() {
  local missing=""
  for pkg in "$@"; do
    if ! opkg list-installed | grep -q "^$pkg"; then
      missing="$missing $pkg"
    fi
  done
  if [ -n "$missing" ]; then
    print_message "Устанавливаем:$missing"
    opkg update >/dev/null 2>&1
    opkg install $missing
    echo ""
  fi
}

packages_checker curl tar findutils jq libcurl
curl -fLsS "https://raw.githubusercontent.com/spatiumstas/$REPO/$BRANCH/$SCRIPT" --output "$TMP_DIR/$SCRIPT" || exit 1
mv "$TMP_DIR/$SCRIPT" "$OPT_DIR/$SCRIPT"
chmod +x $OPT_DIR/$SCRIPT
cd $OPT_DIR/bin
ln -sf $OPT_DIR/$SCRIPT $OPT_DIR/bin/keenkit
exec $OPT_DIR/$SCRIPT
