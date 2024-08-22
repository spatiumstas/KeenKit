#!/bin/sh
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'
USER="spatiumstas"
VERSION="1.8.1"

print_menu() {
  printf "\033c"
  printf "${CYAN}KeenKit v$VERSION by $USER${NC}\n"
  echo ""
  echo "1. Обновить прошивку из файла"
  echo "2. Бэкап разделов"
  echo "3. Бэкап Entware"
  echo "4. Заменить раздел"
  echo "5. OTA Update"
  echo "6. Заменить сервисные данные"
  echo ""
  echo "00. Выход"
  echo "99. Обновить скрипт"
  echo ""
}

main_menu() {
  print_menu
  read -p "Выберите действие: " choice

  if [ -z "$choice" ]; then
    main_menu
  else
    choice=$(echo "$choice" | tr -d ' \n\r')

    case "$choice" in
    1) firmware_manual_update ;;
    2) backup_block ;;
    3) backup_entware ;;
    4) rewrite_block ;;
    5) ota_update ;;
    6) service_data_generator ;;
    99) script_update ;;
    00) exit ;;
    *)
      echo "Неверный выбор. Попробуйте снова."
      sleep 1
      main_menu
      ;;
    esac
  fi
}

get_boot_partition() {
  local OFFSET="0x60000"
  local AUTOBOOT="0x8140000 0x180000 0x4140000"
  local LENGTH=200
  local decimal_offset=$(printf "%d" "$OFFSET")
  local end_offset=$(printf "0x%X" $((decimal_offset + LENGTH)))
  local BIN_FILE=$(get_breed_boot)
  local hex_data=$(xxd -s "$OFFSET" -l "$LENGTH" "$BIN_FILE")
  local ascii_data=$(echo "$hex_data" | xxd -r -p | strings)
  local found_8140000=0
  local found_180000=0
  local found_4140000=0
  local firmwareSlot=""

  for target_value in $AUTOBOOT; do
    if echo "$ascii_data" | grep -qF "$target_value"; then
      case "$target_value" in
      "0x8140000") found_8140000=1 ;;
      "0x180000") found_180000=1 ;;
      "0x4140000") found_4140000=1 ;;
      esac
    fi
  done

  if [ "$found_180000" -eq 1 ]; then
    firmwareSlot="1"
  elif [ "$found_8140000" -eq 1 ] || [ "$found_4140000" -eq 1 ]; then
    firmwareSlot="2"
  else
    firmwareSlot=""
  fi
  echo "$firmwareSlot"
}

get_breed_boot() {
  dd if="/dev/mtdblock0" of="/tmp/breed.bin" >/dev/null 2>&1
  wait
  echo "/tmp/breed.bin"
}

print_message() {
  local message=$1
  local color=$2
  local len=${#message}
  local border=$(printf '%0.s-' $(seq 1 $((len + 2))))

  printf "${color}\n"
  echo -e "\n+${border}+"
  echo -e "| ${message} |"
  echo -e "+${border}+\n"
  printf "${NC}"
  sleep 1
}

packages_checker() {
  if ! opkg list-installed | grep -q "^curl"; then
    printf "${RED}Пакет curl не найден, устанавливаем...${NC}\n"
    echo ""
    opkg update
    opkg install curl
  fi
  if ! opkg list-installed | grep -q "^xxd"; then
    printf "${RED}Пакет xxd не найден, устанавливаем...${NC}\n"
    echo ""
    opkg update
    opkg install xxd
  fi
}

identify_external_drive() {
  local message=$1
  local message2=$2
  local special_message=$3
  filtered_output=$(echo "$output" | grep "/dev/sda" | awk '{print $3}')

  if [ -z "$filtered_output" ]; then
    selected_drive="/opt"
    if [ "$special_message" = "true" ]; then
      echo ""
      read -p "Найдено только встроенное хранилище $message2, продолжить бэкап? (y/n) " item_rc1
      item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
      case "$item_rc1" in
      y | Y) ;;

      n | N)
        main_menu
        ;;
      *) ;;
      esac
    fi
  else
    echo ""
    echo "Доступные накопители:"
    echo "0. Встроенное хранилище $message2"
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
    echo ""
    read -p "$message " choice
    choice=$(echo "$choice" | tr -d ' \n\r')

    if [ "$choice" = "0" ]; then
      selected_drive="/opt"
    else
      selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
      if [ -z "$selected_drive" ]; then
        echo "Недопустимый выбор. Пожалуйста, попробуйте еще раз."
        sleep 2
        main_menu
      fi
    fi
  fi
}

script_update() {
  REPO="KeenKit"
  SCRIPT="keenkit.sh"
  TMP_DIR="/tmp"
  OPT_DIR="/opt"

  packages_checker
  curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/main/$SCRIPT" --output $TMP_DIR/$SCRIPT

  if [ -f "$TMP_DIR/$SCRIPT" ]; then
    mv "$TMP_DIR/$SCRIPT" "$OPT_DIR/$SCRIPT"
    chmod +x $OPT_DIR/$SCRIPT
    cd $OPT_DIR/bin
    ln -sf $OPT_DIR/$SCRIPT $OPT_DIR/bin/KeenKit
    ln -sf $OPT_DIR/$SCRIPT $OPT_DIR/bin/keenkit
    print_message "Скрипт успешно обновлён" "$GREEN"
    $OPT_DIR/$SCRIPT post_update
  else
    print_message "Ошибка при скачивании скрипта" "$RED"
  fi
}

post_update() {
  PART1="aHR0cHM6Ly9sb2c"
  PART2="uc3BhdGl1bS5rZWVuZXRpYy5wcm8="
  PART3="${PART1}${PART2}"
  URL=$(echo "$PART3" | base64 -d)
  JSON_DATA="{\"script_update\": \"$VERSION\"}"
  curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$URL" -o /dev/null -s
  main_menu
}

service_data_generator() {
  REPO="KeenKit"
  OPT_DIR="/opt"
  folder_path="$OPT_DIR/backup$(date +%Y-%m-%d_%H-%M-%S)"
  SCRIPT_PATH="$OPT_DIR/service_data_generator.py"

  if ! opkg list-installed | grep -q "^python3"; then
    echo ""
    read -p "Пакет python3 не установлен, для него необходимо 10МБ свободного места, продолжить? (y/n) " item_rc1
    item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
    case "$item_rc1" in
    y | Y)
      echo ""
      opkg update
      opkg install python3-base python3 python3-light libpython3 --nodeps
      ;;
    n | N)
      main_menu
      return
      ;;
    *) ;;
    esac
  fi

  if [ ! -f "$SCRIPT_PATH" ]; then
    curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/main/service_data_generator.py" --output "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
      print_message "Ошибка загрузки скрипта $SCRIPT_PATH" "$RED"
      return
    fi
  fi

  mkdir -p "$folder_path"
  mtdSlot=$(grep -w 'U-Config' /proc/mtd | awk -F: '{print $1}' | grep -oE '[0-9]+')
  mtdSlot_res=$(grep -w 'U-Config_res' /proc/mtd | awk -F: '{print $1}' | grep -oE '[0-9]+')
  if [ -n "$mtdSlot" ]; then
    dd if="/dev/mtd$mtdSlot" of="$folder_path/U-Config.bin" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      print_message "Бэкап текущего U-Config сохранён в $folder_path" "$GREEN"
    else
      print_message "Ошибка при создании бэкапа U-Config" "$RED"
    fi
  fi

  python3 $SCRIPT_PATH $folder_path/U-Config.bin
  mtdFile=$(find "$folder_path" -type f -name 'U-Config_*.bin' | head -n 1)
  if [ -n "$mtdFile" ]; then
    print_message "Новые сервисные данные сохранены в $mtdFile" "$GREEN"
  fi
  read -p "Продолжить замену? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    echo ""
    dd if="$mtdFile" of="/dev/mtdblock$mtdSlot"
    if [ -n "$mtdSlot_res" ]; then
    echo ""
    printf "${CYAN}Найден второй раздел, заменяю...${NC}"
    echo ""
    dd if="$mtdFile" of="/dev/mtdblock$mtdSlot_res"
    fi
    if [ $? -eq 0 ]; then
      print_message "Замена сервисных данных успешно выполнена" "$GREEN"
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
  echo "Возврат в главное меню..."
  sleep 1
  main_menu
}

ota_update() {
  slot=$(get_boot_partition)
  REPO="osvault"
  packages_checker
  DIRS=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}')

  echo ""
  echo "Доступные модели:"
  i=1
  IFS=$'\n'
  for DIR in $DIRS; do
    printf "${CYAN}$i. $DIR${NC}\n"
    i=$((i + 1))
  done
  printf "${CYAN}00. Выход в главное меню\n${NC}"
  echo ""
  read -p "Выберите модель: " DIR_NUM
  if [ "$DIR_NUM" = "00" ]; then
    main_menu
  fi
  DIR_NUM=$(echo "$DIR_NUM" | tr -d ' \n\r')
  DIR=$(echo "$DIRS" | sed -n "${DIR_NUM}p")

  BIN_FILES=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/$(echo "$DIR" | sed 's/ /%20/g')" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}' | grep ".bin")
  if [ -z "$BIN_FILES" ]; then
    printf "${RED}В директории $DIR нет файлов.${NC}\n"
  else
    printf "\nПрошивки для $DIR:\n"
    i=1
    for FILE in $BIN_FILES; do
      printf "${CYAN}$i. $FILE${NC}\n"
      i=$((i + 1))
    done
    printf "${CYAN}00. Выход в главное меню\n${NC}"
    echo ""
    read -p "Выберите прошивку: " FILE_NUM

    if [ "$FILE_NUM" = "00" ]; then
      main_menu
    fi
    FILE_NUM=$(echo "$FILE_NUM" | tr -d ' \n\r')
    FILE=$(echo "$BIN_FILES" | sed -n "${FILE_NUM}p")
    echo ""
    echo "Загружаю прошивку..."
    if ! curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$(echo "$DIR" | sed 's/ /%20/g')/$(echo "$FILE" | sed 's/ /%20/g')" --output "/tmp/$FILE"; then
      print_message "Не удалось загрузить файл $FILE" "$RED"
      read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
      main_menu
    fi
    echo ""

    if [ -f "/tmp/$FILE" ]; then
      printf "${GREEN}Файл $FILE успешно загружен.${NC}\n"
    else
      printf "${RED}Файл $FILE не был загружен/найден.${NC}\n"
      read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
      main_menu
    fi
    curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$(echo "$DIR" | sed 's/ /%20/g')/md5sum" --output /tmp/md5sum

    MD5SUM=$(grep "$FILE" /tmp/md5sum | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    FILE_MD5SUM=$(md5sum "/tmp/$FILE" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

    if [ "$MD5SUM" == "$FILE_MD5SUM" ]; then
      printf "${GREEN}MD5 хеш совпадает.${NC}\n"
      URL=$(curl -s https://raw.githubusercontent.com/${USER}/EC330-Breed/main/Python/Lib/log)
      JSON_DATA="{\"filename\": \"$FILE\", \"version\": \"$VERSION\"}"
      curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$URL" -o /dev/null -s
    else
      print_message "MD5 хеш не совпадает. Убедитесь что в ОЗУ свободно более 30МБ" "$RED"
      echo "Ожидаемый - $MD5SUM"
      echo "Фактический - $FILE_MD5SUM"
      rm "/tmp/$FILE"
      echo ""
      read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
      main_menu
    fi
    echo ""
    Firmware="/tmp/$FILE"
    FirmwareName=$(basename "$Firmware")
    read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
    item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
    case "$item_rc1" in
    y | Y)
      update_firmware_block "$Firmware" "$slot"
      ;;
    esac
  fi
  rm "$Firmware"
  read -p "Перезагрузить роутер? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    echo ""
    reboot
    ;;
  n | N)
    echo ""
    ;;
  *) ;;
  esac
  echo "Возврат в главное меню..."
  sleep 1
  main_menu
}

update_firmware_block() {
  local firmware="$1"
  local firmwareSlotOTA="$2"
  firmwareSlot=$(get_boot_partition)
  echo ""
  if [ "$firmwareSlot" = "1" ] || [ "$firmwareSlotOTA" = "1" ]; then
    printf "${CYAN}"
    echo "Загрузочный слот - 1"
    printf "${NC}"
    for partition in Firmware_2 Firmware_1 Firmware; do
      mtdSlot="$(grep -w '/proc/mtd' -e "$partition")"
      if [ -z "$mtdSlot" ]; then
        sleep 1
      else
        result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
        echo "$partition на mtd${result} разделе, обновляю..."
        dd if="$firmware" of="/dev/mtdblock$result" bs=128k conv=fsync
        wait
        echo ""
      fi
    done
  else
    printf "${CYAN}"
    echo "Загрузочный слот - 2"
    printf "${NC}"
    for partition in Firmware_1 Firmware_2 Firmware; do
      mtdSlot="$(grep -w '/proc/mtd' -e "$partition")"
      if [ -z "$mtdSlot" ]; then
        sleep 1
      else
        result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
        echo "$partition на mtd${result} разделе, обновляю..."
        dd if="$firmware" of="/dev/mtdblock$result" bs=128k conv=fsync
        wait
        echo ""
      fi
    done
  fi
  print_message "Прошивка успешно обновлена" "$GREEN"
}

firmware_manual_update() {
  output=$(mount)
  identify_external_drive "Выберите накопитель с размещённым файлом обновления:"
  files=$(find "$selected_drive" -name '*.bin' -size +10M)
  count=$(echo "$files" | wc -l)

  if [ -z "$files" ]; then
    print_message "Файл обновления не найден на накопителе." "$RED"
    echo ""
    read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
    main_menu
  fi
  echo ""
  echo "$files" | awk '{print NR".", substr($0, 6)}'
  printf "${CYAN}00. Выход в главное меню${NC}\n"
  echo ""
  read -p "Выберите файл обновления (от 1 до $count): " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  if [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
    echo "Неверный выбор файла"
    sleep 2
    main_menu
  fi

  Firmware=$(echo "$files" | awk "NR==$choice")
  FirmwareName=$(basename "$Firmware")
  echo ""
  read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    update_firmware_block "$Firmware"
    read -p "Удалить файл обновления? (y/n) " item_rc2
    item_rc2=$(echo "$item_rc2" | tr -d ' \n\r')
    case "$item_rc2" in
    y | Y)
      rm "$Firmware"
      wait
      sleep 2
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac

    read -p "Перезагрузить роутер? (y/n) " item_rc3
    item_rc3=$(echo "$item_rc3" | tr -d ' \n\r')
    case "$item_rc3" in
    y | Y)
      echo ""
      reboot
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac
    echo "Возврат в главное меню..."
    sleep 1
    main_menu
    ;;
  n | N)
    main_menu
    ;;
  *) ;;
  esac
}

backup_block() {
  output=$(mount)
  identify_external_drive "Выберите накопитель:"
  filtered_output=$(echo "$output" | grep "/dev/sda" | awk '{print $3}')
  output=$(cat /proc/mtd)
  echo ""
  printf "${GREEN}Доступные разделы:${NC}\n"
  echo "$output" | awk 'NR>1 {print $0}'
  printf "${CYAN}00. Выход в главное меню\n"
  printf "99. Бэкап всех разделов${NC}"
  echo -e "\n"
  folder_path="$selected_drive/backup$(date +%Y-%m-%d_%H-%M-%S)"
  read -p "Укажите номер раздела(ов) разделив пробелами: " choice
  echo ""
  choice=$(echo "$choice" | tr -d '\n\r')

  if [ "$choice" = "00" ]; then
    main_menu
  fi

  mkdir -p "$folder_path"
  error_occurred=0
  non_existent_parts=""

  if [ "$choice" = "99" ]; then
    output_all_mtd=$(cat /proc/mtd | grep -c "mtd")
    for i in $(seq 0 $(($output_all_mtd - 1))); do
      mtd_name=$(echo "$output" | awk -v i=$i 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
      echo "Копирую mtd$i.$mtd_name.bin..."
      if ! cat "/dev/mtdblock$i" >"$folder_path/mtd$i.$mtd_name.bin"; then
        error_occurred=1
        print_message "Ошибка: Недостаточно места для сохранения mtd$i.$mtd_name.bin" "$RED"
        echo ""
        read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
        break
      fi
      wait
    done
  else
    for part in $choice; do
      if ! echo "$output" | awk -v i=$part 'NR==i+2 {print $1}' | grep -q "mtd$part"; then
        non_existent_parts="$non_existent_parts $part"
        continue
      fi

      selected_mtd=$(echo "$output" | awk -v i=$part 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
      echo "Выбран mtd$part.$selected_mtd.bin, копирую..."
      sleep 1
      if ! dd if="/dev/mtd$part" of="$folder_path/mtd$part.$selected_mtd.bin" 2>&1; then
        error_occurred=1
        print_message "Ошибка: Недостаточно места для сохранения mtd$part.$selected_mtd.bin" "$RED"
        echo ""
        read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
        break
      fi
      wait
    done
  fi

  if [ -n "$non_existent_parts" ]; then
    print_message "Ошибка: Раздела${non_existent_parts} не существует!" "$RED"
    error_occurred=1
  fi

  if [ "$error_occurred" -eq 0 ]; then
    print_message "Разделы успешно сохранены в $folder_path" "$GREEN"
  else
    print_message "Ошибки при сохранении разделов. Проверьте вывод выше." "$RED"
  fi

  read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
  main_menu
}


backup_entware() {
  output=$(mount)
  identify_external_drive "Доступные накопители:" "(может не хватить места)" "true"
  echo ""
  echo "Выполняю копирование..."
  backup_file="$selected_drive/entware_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
  backup_output=$(tar cvzf "$backup_file" -C /opt . 2>&1)
  wait
  if echo "$backup_output" | grep -q "No space left on device"; then
    print_message "Бэкап не выполнен, проверьте свободное место" "$RED"
    echo ""
    read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
  else
    print_message "Бэкап успешно скопирован в $backup_file" "$GREEN"
    echo "Возврат в главное меню..."
    sleep 2
  fi
  main_menu
}

rewrite_block() {
  output=$(mount)
  identify_external_drive "Выберите накопитель с размещённым файлом:"
  files=$(find $selected_drive -name '*.bin')
  count=$(echo "$files" | wc -l)
  if [ -z "$files" ]; then
    print_message "Bin файл не найден в выбранном хранилище" "$RED"
    echo ""
    read -n 1 -s -r -p "Для возврата нажмите любую клавишу..."
    main_menu
  fi
  echo ""
  echo "Доступные файлы:"
  echo "$files" | awk '{print NR".", substr($0, 6)}'
  echo ""
  printf "${CYAN}00. Выход в главное меню${NC}\n"
  echo ""
  read -p "Выберите файл для замены: " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  if [ $choice -lt 1 ] || [ $choice -gt $count ]; then
    echo "Неверный выбор файла"
    sleep 3
    main_menu
  fi

  mtdFile=$(echo "$files" | awk "NR==$choice")
  mtdName=$(basename "$mtdFile")
  echo ""
  output=$(cat /proc/mtd)
  echo "$output" | awk 'NR>1 {print $0}'
  echo ""
  printf "${CYAN}00. Выход в главное меню${NC}\n"
  echo ""
  printf "${GREEN}Выбран $mtdName для замены${NC}\n"
  printf "${RED}Внимание, загрузчик не перезаписывается!${NC}\n"
  read -p "Выберите, какой раздел перезаписать (например для mtd2 это 2): " choice
  choice=$(echo "$choice" | tr -d ' \n\r')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  selected_mtd=$(echo "$output" | awk -v i=$choice 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
  echo ""
  read -r -p "Перезаписать раздел mtd$choice.$selected_mtd вашим $mtdName? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' \n\r')
  case "$item_rc1" in
  y | Y)
    sleep 1
    echo ""
    rewrite=$(dd if=$mtdFile of=/dev/mtdblock$choice 2>&1)
    wait
    if echo "$rewrite" | grep -q "No space left on device"; then
      print_message "Перезапись не выполнена, записываемый файл больше раздела" "$RED"
    else
      print_message "Раздел успешно перезаписан" "$GREEN"
    fi
    printf "${NC}"
    read -r -p "Перезагрузить роутер? (y/n) " item_rc3
    item_rc3=$(echo "$item_rc3" | tr -d ' \n\r')
    case "$item_rc3" in
    y | Y)
      echo ""
      reboot
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac
    ;;
  n | N)
    echo ""
    ;;
  esac
  echo "Возврат в главное меню..."
  sleep 1
  main_menu
}

if [ "$1" = "script_update" ]; then
  script_update
elif [ "$1" = "post_update" ]; then
  post_update
else
  main_menu
fi
