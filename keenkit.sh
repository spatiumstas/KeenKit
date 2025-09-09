#!/bin/sh
trap cleanup INT TERM EXIT
export LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'

USERNAME="spatiumstas"
USER='root'
REPO="KeenKit"
SCRIPT="keenkit.sh"
TMP_DIR="/tmp"
OPT_DIR="/opt"
STORAGE_DIR="/storage"
SCRIPT_VERSION="2.3.3"
MIN_RAM_SIZE="256"
PACKAGES_LIST="python3-base python3 python3-light libpython3"
DATE=$(date +%Y-%m-%d_%H-%M)

print_menu() {
  printf "\033c"
  printf "${CYAN}"
  cat <<'EOF'
  _  __               _  ___ _
 | |/ /___  ___ _ __ | |/ (_) |_
 | ' // _ \/ _ \ '_ \| ' /| | __|
 | . \  __/  __/ | | | . \| | |_
 |_|\_\___|\___|_| |_|_|\_\_|\__|

EOF
  printf "${CYAN}Модель:         ${NC}%s\n" "$(get_device) ($(get_hw_id)) | $(get_fw_version) (слот: "$(get_boot_current)")"
  printf "${CYAN}Процессор:      ${NC}%s\n" "$(get_cpu_model) ($(get_architecture)) | $(get_temperature)"
  if get_modem_info=$(get_modem); [ -n "$get_modem_info" ]; then
    printf "${CYAN}Модем:          ${NC}%s\n" "$get_modem_info"
  fi
  printf "${CYAN}ОЗУ:            ${NC}%s\n" "$(get_ram_usage)"
  printf "${CYAN}OPKG:           ${NC}%s\n" "$(get_opkg_storage)"
  printf "${CYAN}Время работы:   ${NC}%s\n" "$(get_uptime)"
  printf "${CYAN}Версия:         ${NC}%s\n\n" "$SCRIPT_VERSION by ${USERNAME}"
  echo "1. Обновить прошивку из файла"
  echo "2. Бэкап разделов"
  echo "3. Бэкап Entware"
  if get_host; then
    echo "4. Заменить раздел"
    echo "5. OTA Update"
    echo "6. Заменить сервисные данные"
  fi
  printf "\n88. Удалить используемые пакеты\n"
  echo "99. Обновить скрипт"
  echo "00. Выход"
  echo ""
}

main_menu() {
  print_menu
  read -p "Выберите действие: " choice
  echo ""
  choice=$(echo "$choice" | tr -d '\032' | tr -d '[A-Z]')

  if [ -z "$choice" ]; then
    main_menu
  else
    case "$choice" in
    1) firmware_manual_update ;;
    2) backup_block ;;
    3) backup_entware ;;
    4) rewrite_block ;;
    5) ota_update ;;
    6) service ;;
    00) exit ;;
    88) packages_delete ;;
    99) script_update "main" ;;
    999) script_update "dev" ;;
    *)
      echo "Неверный выбор. Попробуйте снова."
      sleep 1
      main_menu
      ;;
    esac
  fi
}

print_message() {
  local message="$1"
  local color="${2:-$NC}"
  local border=$(printf '%0.s-' $(seq 1 $((${#message} + 2))))
  printf "${color}\n+${border}+\n| ${message} |\n+${border}+\n${NC}\n"
}

rci_request() {
  local endpoint="$1"
  curl -s "http://localhost:79/rci/$endpoint"
}

get_device() {
  rci_request "show/version" | grep -o '"device": "[^"]*"' | cut -d'"' -f4 2>/dev/null
}

get_fw_version() {
  rci_request "show/version" | grep -o '"title": "[^"]*"' | cut -d'"' -f4 2>/dev/null
}

get_hw_id() {
  rci_request "show/version" | grep -o '"hw_id": "[^"]*"' | cut -d'"' -f4 2>/dev/null
}

get_uptime() {
  local uptime=$(rci_request "show/system" | grep -o '"uptime": "[0-9]*"' | cut -d'"' -f4 2>/dev/null)
  local days=$((uptime / 86400))
  local hours=$(((uptime % 86400) / 3600))
  local minutes=$(((uptime % 3600) / 60))
  local seconds=$((uptime % 60))

  if [ "$days" -gt 0 ]; then
    printf "%d дн. %02d:%02d:%02d\n" "$days" "$hours" "$minutes" "$seconds"
  else
    printf "%02d:%02d:%02d\n" "$hours" "$minutes" "$seconds"
  fi
}

get_ram_usage() {
  local memory=$(rci_request "show/system" | grep -o '"memory": "[^"]*"' | cut -d'"' -f4 2>/dev/null)
  local used=$(echo "$memory" | cut -d'/' -f1)
  local total=$(echo "$memory" | cut -d'/' -f2)
  printf "%d / %d MB\n" "$((used / 1024))" "$((total / 1024))"
}

format_size() {
  local used=$1
  local total=$2
  local used_mb=$((used / 1024 / 1024))
  local total_mb=$((total / 1024 / 1024))
  if [ "$total_mb" -ge 1024 ]; then
    total_gb=$((total / 1024 / 1024 / 1024))
    if [ "$used_mb" -lt 1024 ]; then
      printf "%d MB / %d GB" $used_mb $total_gb
    else
      used_gb=$((used / 1024 / 1024 / 1024))
      printf "%d / %d GB" $used_gb $total_gb
    fi
  else
    printf "%d / %d MB" $used_mb $total_mb
  fi
}

get_opkg_storage() {
  local opkg_label
  opkg_label=$(rci_request "show/sc/opkg/disk" | grep -o '"disk": *"[^\"]*"' | cut -d'"' -f4 | sed 's,/$,,;s,:$,,')
  local ls_json
  ls_json=$(rci_request "ls")
  local free total

  free=$(echo "$ls_json" | grep -A10 "\"$opkg_label:\"" | grep '"free":' | head -1 | grep -o '[0-9]\+')
  total=$(echo "$ls_json" | grep -A10 "\"$opkg_label:\"" | grep '"total":' | head -1 | grep -o '[0-9]\+')

  if [ -n "$free" ] && [ -n "$total" ]; then
    used=$((total - free))
    echo "$(format_size $used $total)"
    return
  fi

  echo "$ls_json" | grep -o '"[A-Za-z0-9 _-]\{3,\}:"' | while read -r entry; do
    entry_name=$(echo "$entry" | tr -d '"')
    block=$(echo "$ls_json" | grep -A10 "\"$entry_name\"")
    is_usb=$(echo "$block" | grep '"storage": *"usb"')
    is_mounted=$(echo "$block" | grep '"mounted": *"yes"')
    if [ -n "$is_usb" ] && [ -n "$is_mounted" ]; then
      free=$(echo "$block" | grep '"free":' | head -1 | grep -o '[0-9]\+')
      total=$(echo "$block" | grep '"total":' | head -1 | grep -o '[0-9]\+')
      if [ -n "$free" ] && [ -n "$total" ]; then
        used=$((total - free))
        echo "$(format_size $used $total)"
        exit 0
      fi
    fi
  done
}

get_internal_storage_size() {
  local flag="$1"
  local ls_json
  ls_json=$(rci_request "ls")
  local free total
  free=$(echo "$ls_json" | grep -A10 '"storage:"' | grep '"free":' | head -1 | grep -o '[0-9]\+')
  total=$(echo "$ls_json" | grep -A10 '"storage:"' | grep '"total":' | head -1 | grep -o '[0-9]\+')
  if [ -n "$free" ] && [ -n "$total" ]; then
    used=$((total - free))
    if [ "$flag" = "free" ]; then
      echo $((free / 1024 / 1024))
    else
      format_size $used $total
    fi
  fi
}

get_ram_size() {
  rci_request "show/system" | grep -o '"memtotal": [0-9]*' | cut -d' ' -f2 | awk '{print int($1 / 1024)}' 2>/dev/null
}

get_boot_current() {
  cat /proc/dual_image/boot_current 2>/dev/null
}

get_ndm_storage() {
  strings /lib/modules/4.9-ndm-5/ndm_storage.ko 2>/dev/null | grep -q "Firmware_2"
}

get_architecture() {
  arch=$(opkg print-architecture | grep -oE 'mips-3|mipsel-3|aarch64-3' | head -n 1)

  case "$arch" in
  "mips-3") echo "mips" ;;
  "mipsel-3") echo "mipsel" ;;
  "aarch64-3") echo "aarch64" ;;
  *) echo "unknown_arch" ;;
  esac
}

get_radio_temp() {
  rci_request "show/interface/$1" | grep -o '"temperature": *[0-9]*' | grep -o '[0-9]*' | head -n1
}

get_temperature() {
  temp_2=$(get_radio_temp WifiMaster0)
  temp_5=$(get_radio_temp WifiMaster1)
  arch=$(get_architecture)
  temp_cpu=""
  cpu_str=""

  if [ "$arch" = "aarch64" ]; then
    temp_cpu_raw=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp | tr -d -c '0-9')
    if [ -n "$temp_cpu_raw" ]; then
      temp_cpu=$((temp_cpu_raw / 1000))
      cpu_str=" | CPU: ${temp_cpu}°C"
    fi
  fi

  if echo "$temp_2" | grep -qE '^[0-9]+$' && echo "$temp_5" | grep -qE '^[0-9]+$'; then
    diff=$((temp_5 - temp_2))
    [ $diff -lt 0 ] && diff=$((-diff))
    if [ $diff -lt 3 ]; then
      echo "Wi-Fi: ${temp_5}°C${cpu_str}"
      return
    fi
    echo "2.4GHz: ${temp_2}°C | 5GHz: ${temp_5}°C${cpu_str}"
  else
    echo "2.4GHz: ${temp_2}°C${cpu_str}"
  fi
}

get_cpu_model() {
  cpu_list="EN75[0-9A-Za-z]* MT76[0-9A-Za-z]* MT79[0-9A-Za-z]*"
  for pattern in $cpu_list; do
    found=$(strings /lib/libndmMwsController.so 2>/dev/null | grep -oE "$pattern" | head -n 1)
    if [ -n "$found" ]; then
      echo "$found"
      return
    fi
  done
  echo "Unknown"
}

get_modem() {
  interfaces_list=$(ndmc -c show interface | grep -A 4 -E "UsbQmi[0-9]*|UsbLte[0-9]*" | grep "id:" | awk '{print $2}')
  [ -z "$interfaces_list" ] && return
  result=""
  first=1
  pad="                  "
  for iface in $interfaces_list; do
    info=$(ndmc -c show interface "$iface")
    plugged=$(echo "$info" | awk -F': ' '/plugged:/ {print $2; exit}')
    [ "$plugged" = "no" ] && continue
    product=$(echo "$info" | awk -F': ' '/product:/ {print $2; exit}')
    temperature=$(echo "$info" | awk -F': ' '/temperature:/ {print $2; exit}')
    carrier=$(echo "$info" | awk '
      /carrier, id =/ {in_carrier=1; band=""; bw=""; if (count++) printf " + "; next}
      in_carrier && /band:/ {band=$2}
      in_carrier && /bandwidth:/ {bw=$2; in_carrier=0; if(band) {printf "B%s", band; if(bw) printf "@%s МГц", bw}}
    ')
    if [ -z "$carrier" ]; then
      band=$(echo "$info" | awk -F': ' '/band:/ {print $2; exit}')
      bandwidth=$(echo "$info" | awk -F': ' '/bandwidth:/ {print $2; exit}')
      if [ -n "$band" ]; then
        carrier="B${band}"
        [ -n "$bandwidth" ] && carrier="${carrier}@${bandwidth} МГц"
      fi
    fi
    modem_name="$product"
    [ -n "$carrier" ] && modem_name="$modem_name | $carrier"
    [ -n "$temperature" ] && modem_name="$modem_name | ${temperature}°C"
    if [ $first -eq 1 ]; then
      result="$modem_name"
      first=0
    else
      result="$result\n$pad$modem_name"
    fi
  done
  echo -e "$result"
}

get_host() {
  rci_request "show/ndss" | grep -q "127.0.0.1"
}

check_host() {
  if ! get_host; then
    main_menu
  fi
}

packages_checker() {
  local packages="$1"
  local flag="$2"
  local missing=""

  for pkg in $packages; do
    if ! opkg list-installed | grep -q "^$pkg"; then
      missing="$missing $pkg"
    fi
  done

  if [ -n "$missing" ]; then
    print_message "Устанавливаем:$missing" "$GREEN"
    opkg update >/dev/null 2>&1
    opkg install $missing $flag
    echo ""
  fi
}

packages_delete() {
  delete_log=$(opkg remove $PACKAGES_LIST --autoremove 2>&1)
  removed_packages=""
  failed_packages=""

  for package in $PACKAGES_LIST; do
    if echo "$delete_log" | grep -q "Removing package $package"; then
      removed_packages="$removed_packages $package"
    elif echo "$delete_log" | grep -q "Package $package is depended upon by packages"; then
      failed_packages="$failed_packages $package"
    fi
  done

  if [ -n "$removed_packages" ]; then
    print_message "Пакеты успешно удалены:$removed_packages" "$GREEN"
  fi

  if [ -n "$failed_packages" ]; then
    print_message "Следующие пакеты не были удалены из-за зависимостей:$failed_packages" "$RED"
  fi

  if [ -z "$removed_packages" ] && [ -z "$failed_packages" ]; then
    print_message "Используемые пакеты не установлены" "$CYAN"
  fi

  exit_function
}

perform_dd() {
  local input_file="$1"
  local output_file="$2"

  output=$(dd if="$input_file" of="$output_file" conv=fsync 2>&1 | tee /dev/tty)

  if echo "$output" | grep -iq "error\|can't"; then
    print_message "Ошибка при перезаписи раздела" "$RED"
    umountFS
    exit_function
  fi
}

select_drive() {
  local message="$1"
  labels=""
  uuids=""
  index=2
  media_found=0
  media_output=$(ndmc -c show media)
  current_manufacturer=""

  if [ -z "$media_output" ]; then
    print_message "Не удалось получить список накопителей" "$RED"
    return 1
  fi

  echo "0. Временное хранилище (tmp)"
  echo "1. Встроенное хранилище ($(get_internal_storage_size))"

  while IFS= read -r line; do
    case "$line" in
    *"name: Media"*)
      media_found=1
      current_manufacturer=""
      ;;
    *"manufacturer:"*)
      if [ "$media_found" = "1" ]; then
        current_manufacturer=$(echo "$line" | cut -d ':' -f2- | sed 's/^ *//g')
      fi
      ;;
    *"uuid:"*)
      if [ "$media_found" = "1" ]; then
        uuid=$(echo "$line" | cut -d ':' -f2- | sed 's/^ *//g')
        read -r label_line
        read -r fstype_line
        read -r state_line
        read -r total_line
        read -r free_line

        label=$(echo "$label_line" | cut -d ':' -f2- | sed 's/^ *//g')
        fstype=$(echo "$fstype_line" | cut -d ':' -f2- | sed 's/^ *//g')
        total_bytes=$(echo "$total_line" | cut -d ':' -f2- | sed 's/^ *//g')
        free_bytes=$(echo "$free_line" | cut -d ':' -f2- | sed 's/^ *//g')
        used_bytes=$((total_bytes - free_bytes))

        if [ "$fstype" = "swap" ]; then
          uuid=""
          continue
        fi

        if [ -n "$label" ]; then
          display_name="$label"
        elif [ -n "$current_manufacturer" ]; then
          display_name="$current_manufacturer"
        else
          display_name="Unknown"
        fi

        echo "$index. $display_name ($(echo "$fstype" | tr '[:lower:]' '[:upper:]'), $(format_size $used_bytes $total_bytes))"
        labels="$labels \"$display_name\""
        uuids="$uuids $uuid"
        index=$((index + 1))
        uuid=""
      fi
      ;;
    esac
  done <<EOF
$media_output
EOF

  echo ""
  read -p "$message " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  echo ""
  case "$choice" in
  0) selected_drive="$TMP_DIR" ;;
  1) selected_drive="$STORAGE_DIR" ;;
  *)
    if [ -n "$uuids" ]; then
      selected_drive=$(echo "$uuids" | awk -v choice="$choice" '{split($0, a, " "); print a[choice-1]}')
      if [ -z "$selected_drive" ]; then
        print_message "Неверный выбор" "$RED"
        exit_function
      fi
      selected_drive="/tmp/mnt/$selected_drive"
    else
      print_message "Неверный выбор" "$RED"
      exit_function
    fi
    ;;
  esac
}

has_an_external_storage() {
  for line in $(mount | grep "/dev/sd"); do
    if echo "$line" | grep -q "$OPT_DIR"; then
      echo ""
    else
      return 0
    fi
  done
  return 1
}

backup_config() {
  if has_an_external_storage; then
    print_message "Обнаружены внешние накопители" "$CYAN"
    read -p "Создать бэкап startup-config? (y/n) " user_input
    user_input=$(echo "$user_input" | tr -d ' \n\r')

    case "$user_input" in
    y | Y)
      echo ""
      select_drive "Выберите накопитель для бэкапа:"

      if [ -n "$selected_drive" ]; then
        local device_uuid=$(echo "$selected_drive" | awk -F'/' '{print $NF}')
        local folder_path="$device_uuid:/backup$DATE"
        local backup_file="$folder_path/$(get_hw_id)_$(get_fw_version)_startup-config.txt"
        mkdir -p "$selected_drive/backup$DATE"
        ndmc -c "copy startup-config $backup_file"

        if [ $? -eq 0 ]; then
          print_message "Startup-config сохранен в $backup_file" "$GREEN"
        else
          print_message "Ошибка при сохранении бэкапа" "$RED"
        fi
      else
        echo "Бэкап не выполнен, накопитель не выбран."
      fi
      ;;
    *)
      echo ""
      ;;
    esac
  fi
}

exit_function() {
  echo ""
  read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
  main_menu
}

exit_main_menu() {
  printf "\n${CYAN}00. Выход в главное меню${NC}\n\n"
}

script_update() {
  packages_checker "curl"
  BRANCH="$1"
  curl -L -s "https://raw.githubusercontent.com/$USERNAME/$REPO/$BRANCH/$SCRIPT" --output $TMP_DIR/$SCRIPT

  if [ -f "$TMP_DIR/$SCRIPT" ]; then
    mv "$TMP_DIR/$SCRIPT" "$OPT_DIR/$SCRIPT"
    chmod +x $OPT_DIR/$SCRIPT
    if [ ! -f "$OPT_DIR/bin/keenkit" ]; then
      cd $OPT_DIR/bin
      ln -s "$OPT_DIR/$SCRIPT" "$OPT_DIR/bin/keenkit"
    fi
    print_message "Скрипт успешно обновлён" "$GREEN"
    $OPT_DIR/$SCRIPT post_update
  else
    response=$(curl -L -s "https://raw.githubusercontent.com/$USERNAME/$REPO/$BRANCH/$SCRIPT" | head -n1)
    print_message "Ошибка $response при обновлении скрипта" "$RED"
    exit_function
  fi
}

url() {
  URL=$(echo "aHR0cHM6Ly9sb2cuc3BhdGl1bS5uZXRjcmF6ZS5wcm8=" | base64 -d)
  echo "${URL}"
}

post_update() {
  URL=$(url)
  JSON_DATA="{\"script_update\": \"$SCRIPT_VERSION\"}"
  curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$URL" -o /dev/null -s --fail --max-time 2 --retry 0
  main_menu
}

internet_checker() {
  if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    print_message "Нет доступа к интернету. Проверьте подключение." "$RED"
    exit_function
  fi
}

mountFS() {
  mount -t tmpfs tmpfs /tmp
  print_message "LockFS: true"
}

umountFS() {
  umount /tmp
  print_message "UnlockFS: true"
}

get_osvault() {
  echo "b3N2YXVsdC5rZWVuZXRpY3BvcnRlZC5kZXY=" | base64 -d
}

show_progress() {
  local total_size="$1"
  local downloaded=0
  local progress=0
  local file_path="$2"
  local file_name="$3"

  while [ "$downloaded" -lt "$total_size" ]; do
    if [ -f "$file_path" ]; then
      downloaded=$(ls -l "$file_path" | awk '{print $5}')
      progress=$((downloaded * 100 / total_size))
      printf "\rЗагружаю $file_path... (%d%%)" "$progress"
    fi
    sleep 1
  done
  printf "\n"
}

get_ota_fw_name() {
  local FILE="$1"
  URL=$(url)
  JSON_DATA="{\"filename\": \"$FILE\", \"version\": \"$SCRIPT_VERSION\"}"
  curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$URL" -o /dev/null -s --fail --max-time 2 --retry 0
}

ota_update() {
  check_host
  packages_checker "curl findutils"
  internet_checker
  osvault="$(get_osvault)/osvault"
  REQUEST=$(curl -L -s "$osvault")
  DIRS=$(echo "$REQUEST" | grep -oP 'href="\K[^"]+' | grep -v '^\.\./$' | grep -v '^/$' | sed 's|/$||' | sed 's|%20| |g')

  if [ -z "$DIRS" ]; then
    status_line=$(wget -S --spider -O /dev/null "$osvault" 2>&1 | grep 'HTTP/' | tail -n1)
    http_text=$(echo "$status_line" | cut -d' ' -f3-)
    print_message "Ошибка $http_text при получении данных, попробуйте позже" "$RED"
    exit_function
  fi

  echo "Доступные модели:"
  i=1
  echo "$DIRS" | while IFS= read -r DIR; do
    printf "%d. %s\n" "$i" "$DIR"
    i=$((i + 1))
  done
  exit_main_menu
  dir_count=$(echo "$DIRS" | wc -l)
  while true; do
    read -p "Выберите модель (от 1 до $dir_count): " DIR_NUM
    if [ "$DIR_NUM" = "00" ]; then
      main_menu
    fi
    if echo "$DIR_NUM" | grep -qE '^[0-9]+$' && [ "$DIR_NUM" -ge 1 ] && [ "$DIR_NUM" -le "$dir_count" ]; then
      break
    else
      print_message "Неверный выбор. Выберите от 1 до $dir_count." "$RED"
    fi
  done
  DIR=$(echo "$DIRS" | sed -n "${DIR_NUM}p")
  DIR_ENCODED=$(echo "$DIR" | sed 's/ /%20/g')

  REQUEST=$(curl -L -s "$osvault/$DIR_ENCODED/")
  BIN_FILES=$(echo "$REQUEST" | grep -oP 'href="\K[^"]+' | grep '\.bin$' | sed 's|%20| |g')

  if [ -z "$BIN_FILES" ]; then
    printf "${RED}В директории $DIR нет файлов.${NC}\n"
    exit_function
  else
    printf "\nПрошивки для $DIR:\n"
    i=1
    echo "$BIN_FILES" | while IFS= read -r FILE; do
      printf "%d. %s\n" "$i" "$FILE"
      i=$((i + 1))
    done
    exit_main_menu
    file_count=$(echo "$BIN_FILES" | wc -l)
    while true; do
      read -p "Выберите прошивку (от 1 до $file_count): " FILE_NUM
      if [ "$FILE_NUM" = "00" ]; then
        unset FILE
        unset DOWNLOAD_PATH
        unset use_mount
        unset progress_pid
        main_menu
        return
      fi
      if echo "$FILE_NUM" | grep -qE '^[0-9]+$' && [ "$FILE_NUM" -ge 1 ] && [ "$FILE_NUM" -le "$file_count" ]; then
        break
      else
        print_message "Неверный выбор. Выберите от 1 до $file_count." "$RED"
      fi
    done
    FILE=$(echo "$BIN_FILES" | sed -n "${FILE_NUM}p")
    FILE_ENCODED=$(echo "$FILE" | sed 's/ /%20/g')

    if [ -z "$FILE" ]; then
      print_message "Файл не выбран" "$RED"
      exit_function
    fi
    total_size=$(curl -sIL "$osvault/$DIR_ENCODED/$FILE_ENCODED" | grep -i content-length | tail -n 1 | awk '{print $2}' | tr -d '\r')
    ram_size=$(get_ram_size)
    total_size_mb=$((total_size / 1024 / 1024))
    free_space_mb=$(get_internal_storage_size free)
    if [ "$ram_size" -lt "$MIN_RAM_SIZE" ] || [ "$free_space_mb" -ge "$total_size_mb" ]; then
      DOWNLOAD_PATH="$STORAGE_DIR"
      use_mount=true
    else
      DOWNLOAD_PATH="$TMP_DIR"
      use_mount=false
    fi
    mkdir -p "$DOWNLOAD_PATH"
    echo ""
    show_progress "$total_size" "$DOWNLOAD_PATH/$FILE" "$FILE" &
    progress_pid=$!
    curl -L --silent "$osvault/$DIR_ENCODED/$FILE_ENCODED" --output "$DOWNLOAD_PATH/$FILE"
    wait $progress_pid
    if [ ! -f "$DOWNLOAD_PATH/$FILE" ]; then
      printf "${RED}Файл $FILE не был загружен/найден.${NC}\n"
      exit_function
    fi

    curl -L -s "$osvault/$DIR_ENCODED/md5sum" --output "$DOWNLOAD_PATH/md5sum"
    MD5SUM_REMOTE=$(grep "$FILE" "$DOWNLOAD_PATH/md5sum" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    MD5SUM_LOCAL=$(md5sum "$DOWNLOAD_PATH/$FILE" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

    if [ "$MD5SUM_REMOTE" != "$MD5SUM_LOCAL" ]; then
      printf "${RED}MD5 хеш не совпадает.${NC}\n"
      echo "Ожидаемый: $MD5SUM_REMOTE"
      echo "Фактический: $MD5SUM_LOCAL"
      rm -f "$DOWNLOAD_PATH/$FILE"
      rm -f "$DOWNLOAD_PATH/md5sum"
      exit_function
    fi

    printf "${GREEN}MD5 хеш совпадает${NC}\n\n"
    read -p "$(printf "Выбран ${GREEN}$FILE${NC} для обновления, всё верно? (y/n) ")" CONFIRM
    case "$CONFIRM" in
    y | Y)
      update_firmware_block "$DOWNLOAD_PATH/$FILE" "$use_mount"
      get_ota_fw_name "$FILE"
      print_message "Прошивка успешно обновлена" "$GREEN"
      ;;
    n | N)
      rm -f "$DOWNLOAD_PATH/$FILE"
      rm -f "$DOWNLOAD_PATH/md5sum"
      exit_function
      ;;
    *) ;;
    esac
    rm -f "$DOWNLOAD_PATH/$FILE"
    rm -f "$DOWNLOAD_PATH/md5sum"
    print_message "Перезагружаю устройство..." "${CYAN}"
    sleep 1
    reboot
  fi
}

update_firmware_block() {
  local firmware="$1"
  local use_mount="$2"
  backup_config
  if [ "$use_mount" = true ] || [[ "$firmware" == *"$STORAGE_DIR"* ]]; then
    mountFS
  fi

  for partition in Firmware Firmware_1 Firmware_2; do
    if [ "$partition" = "Firmware_2" ] && get_ndm_storage; then
      continue
    fi
    mtdSlot="$(grep -w '/proc/mtd' -e "$partition")"
    if [ -z "$mtdSlot" ]; then
      sleep 1
    else
      result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
      echo "$partition на mtd${result} разделе, обновляю..."
      perform_dd "$firmware" "/dev/mtdblock$result"
      echo ""
    fi
  done

  if [ "$use_mount" = true ] || [[ "$firmware" == *"$STORAGE_DIR"* ]]; then
    umountFS
  fi
}

find_files() {
  local search_path="$1"
  local min_size="$2"
  local exclude_pattern="$3"

  local find_cmd="find \"$search_path\" -name '*.bin' -size +${min_size}"

  if [ "$search_path" = "$TMP_DIR" ]; then
    find_cmd="$find_cmd -not -path \"*/mnt/*\""
  fi

  if [ -n "$exclude_pattern" ]; then
    find_cmd="$find_cmd -not -path \"$exclude_pattern\""
  fi

  eval "$find_cmd"
}

firmware_manual_update() {
  packages_checker "findutils"
  ram_size=$(get_ram_size)

  if [ "$ram_size" -lt $MIN_RAM_SIZE ]; then
    print_message "Обновление возможно только со встроенного накопителя Entware" "$CYAN"
    selected_drive="$STORAGE_DIR"
    use_mount=true
  else
    output=$(mount)
    select_drive "Выберите накопитель с размещённым файлом обновления:"
    selected_drive="$selected_drive"
    use_mount=false
  fi

  files=$(find_files "$selected_drive" "1M")
  count=$(echo "$files" | wc -l)

  if [ -z "$files" ]; then
    print_message "Файл обновления не найден на накопителе" "$RED"
    exit_function
  fi

  echo "$files" | sed "s|$selected_drive/||" | awk '{print NR".", $0}'

  exit_main_menu
  read -p "Выберите файл обновления (от 1 до $count): " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  if [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
    print_message "Неверный выбор файла" "$RED"
    exit_function
  fi

  Firmware=$(echo "$files" | awk "NR==$choice")
  FirmwareName=$(basename "$Firmware")
  echo ""
  read -p "$(printf "Выбран ${GREEN}$FirmwareName${NC} для обновления, всё верно? (y/n) ")" item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    update_firmware_block "$Firmware" "$use_mount"
    print_message "Прошивка успешно обновлена" "$GREEN"
    printf "${NC}"
    read -p "Удалить файл обновления? (y/n) " item_rc2
    item_rc2=$(echo "$item_rc2" | tr -d ' \n\r')
    case "$item_rc2" in
    y | Y)
      rm "$Firmware"
      sleep 2
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac
    print_message "Перезагружаю устройство..." "${CYAN}"
    sleep 1
    reboot
    ;;
  esac
  main_menu
}

backup_block() {
  output=$(mount)
  select_drive "Выберите накопитель для бэкапа:"
  mtd_output=$(cat /proc/mtd)
  printf "${GREEN}Доступные разделы:${NC}\n"
  echo "$mtd_output" | awk 'NR>1 {print $0}'
  printf "99. Бэкап всех разделов${NC}\n"
  exit_main_menu
  folder_path="$selected_drive/backup$DATE"
  read -p "Укажите номер(а) раздела(ов) разделив пробелами: " choice
  echo ""
  choice=$(echo "$choice" | tr -d '\n\r')

  if [ "$choice" = "00" ]; then
    main_menu
  fi

  error_occurred=0
  non_existent_parts=""
  valid_parts=0

  if [ "$choice" = "99" ]; then
    output_all_mtd=$(cat /proc/mtd | grep -c "mtd")
    for i in $(seq 0 $(($output_all_mtd - 1))); do
      mtd_name=$(echo "$mtd_output" | awk -v i=$i 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
      echo "Копирую mtd$i.$mtd_name.bin..."
      if [ $valid_parts -eq 0 ]; then
        mkdir -p "$folder_path"
        valid_parts=1
      fi

      if ! cat "/dev/mtdblock$i" >"$folder_path/mtd$i.$mtd_name.bin"; then
        error_occurred=1
        break
      fi
    done
  else
    for part in $choice; do
      if ! echo "$mtd_output" | awk -v i=$part 'NR==i+2 {print $1}' | grep -q "mtd$part"; then
        non_existent_parts="$non_existent_parts $part"
        continue
      fi

      selected_mtd=$(echo "$mtd_output" | awk -v i=$part 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')

      if [ $valid_parts -eq 0 ]; then
        mkdir -p "$folder_path"
        valid_parts=1
      fi

      printf "Выбран ${GREEN}mtd$part.$selected_mtd.bin${NC}, копирую..."
      sleep 1
      echo ""
      if ! dd if="/dev/mtd$part" of="$folder_path/mtd$part.$selected_mtd.bin" 2>&1; then
        error_occurred=1
      fi
      echo ""
    done
  fi

  if [ -n "$non_existent_parts" ]; then
    print_message "Ошибка: Раздела${non_existent_parts} не существует!" "$RED"
    error_occurred=1
  fi

  if [ "$error_occurred" -eq 0 ] && [ $valid_parts -eq 1 ]; then
    print_message "Успешно сохранено в $folder_path" "$GREEN"
  else
    print_message "Ошибка при сохранении." "$RED"
  fi
  exit_function
}

backup_entware() {
  packages_checker "tar"
  output=$(mount)
  select_drive "Выберите накопитель:"
  print_message "Выполняю копирование..." "$CYAN"

  backup_file="$selected_drive/$(get_architecture)_entware_backup_$DATE.tar.gz"
  tar_output=$(tar cvzf "$backup_file" -C "$OPT_DIR" --exclude="$backup_file" . 2>&1)
  log_operation=$(echo "$tar_output" | tail -n 2)

  if echo "$log_operation" | grep -iq "error\|no space left on device"; then
    print_message "Ошибка при создании бэкапа:" "$RED"
    echo "$log_operation"
  else
    print_message "Бэкап успешно скопирован в $backup_file" "$GREEN"
  fi
  exit_function
}

rewrite_block() {
  check_host
  output=$(mount)
  select_drive "Выберите накопитель с размещённым файлом:"
  files=$(find_files "$selected_drive" "60k")
  count=$(echo "$files" | wc -l)
  if [ -z "$files" ]; then
    print_message "Файл для замены не найден в выбранном хранилище" "$RED"
    exit_function
  fi
  echo "Найдены файлы:"
  echo "$files" | sed "s|$selected_drive/||" | awk '{print NR".", $0}'
  exit_main_menu
  read -p "Выберите файл для замены: " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  if [ $choice -lt 1 ] || [ $choice -gt $count ]; then
    print_message "Неверный выбор файла" "$RED"
    exit_function
  fi

  mtdFile=$(echo "$files" | awk "NR==$choice")
  mtdName=$(basename "$mtdFile")
  echo ""
  mtd_output=$(cat /proc/mtd)
  echo "$mtd_output" | awk 'NR>1 {print $0}'
  exit_main_menu
  print_message "Внимание! Загрузчик не перезаписывается!" "$RED"
  read -p "Укажите номер(а) раздела(ов) разделив пробелами: " choice
  choice=$(echo "$choice" | tr -d '\n\r')

  if [ "$choice" = "00" ]; then
    main_menu
  fi

  error_occurred=0
  non_existent_parts=""
  valid_parts=0

  for part in $choice; do
    if [ "$part" = "0" ]; then
      print_message "Загрузчик не перезаписывается!" "$RED"
      continue
    fi

    if ! echo "$mtd_output" | awk -v i=$part 'NR==i+2 {print $1}' | grep -q "mtd$part"; then
      non_existent_parts="$non_existent_parts $part"
      continue
    fi

    selected_mtd=$(echo "$mtd_output" | awk -v i=$part 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
    echo ""
    read -r -p "$(printf "Перезаписать раздел ${CYAN}mtd$part.$selected_mtd${NC} вашим ${GREEN}$mtdName${NC}? (y/n) ")" item_rc1
    item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
    case "$item_rc1" in
    y | Y)
      if [[ "$mtdFile" == *"$STORAGE_DIR"* ]]; then
        mountFS
      fi
      perform_dd "$mtdFile" "/dev/mtdblock$part"
      print_message "Раздел успешно перезаписан" "$GREEN"
      if [[ "$mtdFile" == *"$STORAGE_DIR"* ]]; then
        umountFS
      fi
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac
  done

  if [ -n "$non_existent_parts" ]; then
    print_message "Ошибка: Раздела${non_existent_parts} не существует!" "$RED"
    error_occurred=1
  fi

  if [ "$error_occurred" -eq 0 ]; then
    read -r -p "Перезагрузить роутер? (y/n) " item_rc2
    item_rc2=$(echo "$item_rc2" | tr -d ' \n\r')
    case "$item_rc2" in
    y | Y)
      reboot
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac
  fi
  exit_function
}

service() {
  check_host
  folder_path="$OPT_DIR/backup$DATE"
  SCRIPT_PATH="$TMP_DIR/service.py"
  target_flag=$1
  packages_checker "curl python3-base python3 python3-light libpython3 findutils" "--nodeps"

  curl -L -s "$(get_osvault)/scripts/service.py" --output "$SCRIPT_PATH"
  if [ $? -ne 0 ] || ! head -n1 "$SCRIPT_PATH" | grep -q "^#\|^import\|^def\|^class"; then
    print_message "Ошибка при получении файла, попробуйте позже" "$RED"
    exit_function
  fi

  mkdir -p "$folder_path"
  mtdSlot=$(grep -w 'U-Config' /proc/mtd | awk -F: '{print $1}' | grep -oE '[0-9]+')
  mtdSlot_res=$(grep -w 'U-Config_res' /proc/mtd | awk -F: '{print $1}' | grep -oE '[0-9]+')
  if [ -n "$mtdSlot" ]; then
    perform_dd "/dev/mtd$mtdSlot" "$folder_path/U-Config.bin"
    if [ $? -eq 0 ]; then
      print_message "Бэкап текущего U-Config сохранён в $folder_path" "$GREEN"
    else
      print_message "Ошибка при создании бэкапа U-Config" "$RED"
    fi
  fi

  if [ -n "$target_flag" ]; then
    python3 "$SCRIPT_PATH" "$folder_path/U-Config.bin" "$target_flag"
  else
    python3 "$SCRIPT_PATH" "$folder_path/U-Config.bin"
  fi

  mtdFile=$(find "$folder_path" -type f -name 'U-Config_*.bin' | head -n 1)
  if [ -n "$mtdFile" ]; then
    print_message "Новые сервисные данные сохранены в $mtdFile" "$GREEN"
  fi
  read -p "Продолжить замену? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    echo ""
    printf "${CYAN}Перезаписываю первый раздел...${NC}\n"
    perform_dd "$mtdFile" "/dev/mtdblock$mtdSlot"
    if [ -n "$mtdSlot_res" ]; then
      echo ""
      printf "${CYAN}Найден второй раздел, перезаписываю...${NC}\n"
      perform_dd "$mtdFile" "/dev/mtdblock$mtdSlot_res"
    fi
    if [ $? -eq 0 ]; then
      print_message "Сервисные данные успешно заменены" "$GREEN"
    else
      print_message "Ошибка при выполнении замены" "$RED"
    fi
    ;;
  esac
  read -p "Перезагрузить роутер? (y/n) " item_rc2
  item_rc2=$(echo "$item_rc2" | tr -d ' \n\r')
  case "$item_rc2" in
  y | Y)
    echo ""
    reboot
    ;;
  n | N)
    echo ""
    ;;
  *) ;;
  esac
  exit_function
}

cleanup() {
  pkill -P $$ 2>/dev/null
  exit 0
}

if [ "$1" = "script_update" ]; then
  script_update
elif [ "$1" = "post_update" ]; then
  post_update
else
  main_menu
fi
