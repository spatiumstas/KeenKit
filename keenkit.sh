#!/bin/sh
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'
USER="spatiumstas"

main_menu() {
  printf "\033c"
  printf "${CYAN}KeenKit v1.6 by $USER${NC}\n"
  echo ""
  echo "1. Обновить прошивку"
  echo "2. Бекап разделов"
  echo "3. Бекап Entware"
  echo "4. Заменить раздел"
  echo "5. OTA Update"
  echo ""
  echo "00. Выход"
  echo "99. Обновить скрипт"
  echo ""
  read -p "Выберите действие: " choice
  choice=$(echo "$choice" | tr -d ' ')

  case "$choice" in
  1) firmware_manual_update ;;
  2) backup_block ;;
  3) backup_entware ;;
  4) rewrite_block ;;
  5) ota_update ;;
  99) script_update ;;
  00) exit ;;
  *)
    echo "Неверный выбор. Попробуйте снова."
    sleep 1
    main_menu
    ;;
  esac
}

exception_error() {
  local message=$1
  local len=${#message}
  local border=$(printf '%0.s-' $(seq 1 $((len + 2))))

  printf "${RED}"
  echo -e "\n+${border}+"
  echo -e "| ${message} |"
  echo -e "+${border}+\n"
  printf "${NC}"
  sleep 2
}

successful_message() {
  local message=$1
  local len=${#message}
  local border=$(printf '%0.s-' $(seq 1 $((len + 2))))

  printf "${GREEN}"
  echo -e "\n+${border}+"
  echo -e "| ${message} |"
  echo -e "+${border}+\n"
  printf "${NC}"
  sleep 1
}

identify_external_drive() {
  local message=$1
  filtered_output=$(echo "$output" | grep "/dev/sda" | awk '{print $3}')

  if [ -z "$filtered_output" ]; then
    selected_drive="/opt"
  else
    echo ""
    echo "Доступные накопители:"
    echo "0. Встроенное хранилище (может не хватить места)"
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
    echo ""
    read -p "Выберите накопитель: " choice
    choice=$(echo "$choice" | tr -d ' ')

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

  if ! opkg list-installed | grep -q "^curl"; then
    printf "${RED}Пакет curl не найден, устанавливаем...${NC}\n"
    echo ""
    opkg update
    opkg install curl
  fi

  curl -L -s "https://raw.githubusercontent.com/spatiumstas/KeenKit/main/keenkit.sh" --output $TMP_DIR/$SCRIPT

  if [ -f "$TMP_DIR/$SCRIPT" ]; then
    mv "$TMP_DIR/$SCRIPT" "/opt/$SCRIPT"
    chmod +x /opt/$SCRIPT
    echo ""
    successful_message "Скрипт успешно обновлён"
  else
    exception_error "Ошибка при скачивании скрипта"
  fi
  sleep 2
  /opt/$SCRIPT
}

ota_update() {
  REPO="osvault"

  if ! opkg list-installed | grep -q "^curl"; then
    printf "${RED}Пакет curl не найден, устанавливаем...${NC}\n"
    echo ""
    opkg update
    opkg install curl
  fi

  DIRS=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}')

  echo ""
  echo "Доступные модели:"
  i=1
  IFS=$'\n'
  for DIR in $DIRS; do
    printf "${CYAN}$i. $DIR${NC}\n"
    i=$((i + 1))
  done

  echo ""
  read -p "Выберите модель: " DIR_NUM
  DIR_NUM=$(echo "$DIR_NUM" | tr -d ' ')
  DIR=$(echo "$DIRS" | sed -n "${DIR_NUM}p")

  BIN_FILES=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/$DIR" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}' | grep ".bin")

  if [ -z "$BIN_FILES" ]; then
    printf "${RED}В директории $DIR нет файлов.${NC}\n"
  else
    printf "\nПрошивки для $DIR:\n"
    i=1
    for FILE in $BIN_FILES; do
      printf "${CYAN}$i. $FILE${NC}\n"
      i=$((i + 1))
    done

    echo ""
    read -p "Выберите прошивку: " FILE_NUM
    FILE_NUM=$(echo "$FILE_NUM" | tr -d ' ')
    FILE=$(echo "$BIN_FILES" | sed -n "${FILE_NUM}p")
    echo ""
    echo "Загружаю прошивку..."
    if ! curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$DIR/$FILE" --output /tmp/$FILE; then
      exception_error "}Не удалось загрузить файл $FILE"
      exit 1
    fi
    echo ""

    if [ -f "/tmp/$FILE" ]; then
      printf "${GREEN}Файл $FILE успешно загружен.${NC}\n"
    else
      printf "${RED}Файл $FILE не был загружен/найден.${NC}\n"
      exit 1
    fi
    curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$DIR/md5sum" --output /tmp/md5sum

    MD5SUM=$(grep "$FILE" /tmp/md5sum | awk '{print $1}')

    FILE_MD5SUM=$(md5sum /tmp/$FILE | awk '{print $1}')

    if [ "$MD5SUM" == "$FILE_MD5SUM" ]; then
      printf "${GREEN}MD5 хеш совпадает.${NC}\n"
    else
      exception_error "MD5 хеш не совпадает. Убедитесь что в ОЗУ свободно более 30МБ"
      echo "Ожидаемый - $MD5SUM"
      echo "Фактический - $FILE_MD5SUM"
      rm $FILE
      sleep 2
      main_menu
    fi
    echo ""
    Firmware="/tmp/$FILE"
    FirmwareName=$(basename "$Firmware")
    read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
    item_rc1=$(echo "$item_rc1" | tr -d ' ')
    case "$item_rc1" in
    y | Y)
      echo ""
      mtdSlot="$(grep -w '/proc/mtd' -e 'Firmware_1')"
      result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
      echo "Firmware_1 на mtd$result разделе, обновляю..."
      dd if=$Firmware of=/dev/mtdblock$result
      wait
      echo ""
      mtdSlot2="$(grep -w '/proc/mtd' -e 'Firmware_2')"
      result2=$(echo "$mtdSlot2" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
      echo "Firmware_2 на mtd$result2 разделе, обновляю..."
      dd if=$Firmware of=/dev/mtdblock$result2
      successful_message "Прошивка успешно обновлена"
      ;;
    esac
  fi
  rm $FILE
  read -p "Перезагрузить роутер? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' ')
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
  local firmware=$1
  local mtdblock=$2

  echo "Firmware на mtd${mtdblock} разделе, обновляю..."
  dd if=$firmware of=/dev/mtdblock$mtdblock
  wait
}

firmware_manual_update() {
  output=$(mount)
  identify_external_drive "Выберите накопитель с размещённым файлом обновления:"
  files=$(find $selected_drive -name '*.bin' -size +10M)
  count=$(echo "$files" | wc -l)

  if [ -z "$files" ]; then
    echo ""
    exception_error "Файл обновления не найден"
    echo "Возврат в главное меню..."
    sleep 2
    main_menu
  fi
  echo ""
  echo "$files" | awk '{print NR".", substr($0, 6)}'
  echo ""
  printf "${CYAN}00 - Выход в главное меню${NC}\n"
  read -p "Выберите файл обновления (от 1 до $count): " choice
  choice=$(echo "$choice" | tr -d ' ')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  if [ $choice -lt 1 ] || [ $choice -gt $count ]; then
    echo "Неверный выбор файла"
    sleep 2
    main_menu
  fi

  Firmware=$(echo "$files" | awk "NR==$choice")
  FirmwareName=$(basename "$Firmware")
  echo ""
  printf "${GREEN}"
  read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' ')
  printf "${NC}"
  case "$item_rc1" in
  y | Y)
    echo ""
    mtdSlot="$(grep -w '/proc/mtd' -e 'Firmware_1')"
    result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    update_firmware_block $Firmware $result
    echo ""
    mtdSlot2="$(grep -w '/proc/mtd' -e 'Firmware_2')"
    result2=$(echo "$mtdSlot2" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    update_firmware_block $Firmware $result2
    echo ""
    successful_message "Прошивка успешно обновлена"
    read -p "Удалить файл обновления? (y/n) " item_rc2
    item_rc2=$(echo "$item_rc2" | tr -d ' ')
    case "$item_rc2" in
    y | Y)
      rm $Firmware
      wait
      sleep 2
      ;;
    n | N)
      echo ""
      ;;
    *) ;;
    esac

    read -p "Перезагрузить роутер? (y/n) " item_rc3
    item_rc3=$(echo "$item_rc3" | tr -d ' ')
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
  identify_external_drive "Доступные накопители:"
  filtered_output=$(echo "$output" | grep "/dev/sda" | awk '{print $3}')
  output=$(cat /proc/mtd)
  echo ""
  printf "${GREEN}Доступные разделы:${NC}\n"
  echo "$output" | awk 'NR>1 {print $0}'
  printf "${CYAN}00 - Выход в главное меню\n"
  printf "99 - Бекап всех разделов${NC}"
  echo -e "\n"
  folder_path="$selected_drive/backup$(date +%Y-%m-%d_%H-%M-%S)"
  read -p "Выберите цифру раздела (например для mtd2 это 2): " choice
  choice=$(echo "$choice" | tr -d ' ')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  mkdir -p "$folder_path"
  if [ "$choice" = "99" ]; then
    output_all_mtd=$(cat /proc/mtd | grep -c "mtd")
    for i in $(seq 0 $(($output_all_mtd - 1))); do
      mtd_name=$(echo "$output" | awk -v i=$i 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
      echo "Копирую mtd$i.$mtd_name.bin..."
      cat "/dev/mtdblock$i" >"$folder_path/mtd$i.$mtd_name.bin"
    done

  else
    selected_mtd=$(echo "$output" | awk -v i=$choice 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
    echo "Выбран mtd$choice.$selected_mtd.bin, копирую..."
    echo -e "\n"
    dd if="/dev/mtd$choice" of="$folder_path/mtd$choice.$selected_mtd.bin"
    wait
  fi
  echo ""
  successful_message "Раздел успешно сохранён в $folder_path"
  echo "Возврат в главное меню..."
  sleep 4
  main_menu
}

backup_entware() {
  output=$(mount)
  identify_external_drive
  echo ""
  echo "Выполняю копирование..."
  backup_output=$(tar cvzf "$selected_drive/entware_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz" -C /opt . 2>&1)
  if echo "$backup_output" | grep -q "error"; then
    exception_error
  fi
  wait
  echo ""
  successful_message "Бекап успешно скопирован в $backup_output"
  echo "Возврат в главное меню..."
  sleep 3
  main_menu
}

rewrite_block() {
  output=$(mount)
  identify_external_drive
  files=$(find $selected_drive -name '*.bin')
  count=$(echo "$files" | wc -l)
  if [ -z "$files" ]; then
    echo ""
    exception_error "Bin файл не найден в выбранном хранилище"
    echo "Возврат в главное меню..."
    sleep 1
    main_menu
  fi
  echo ""
  echo "Доступные файлы:"
  echo "$files" | awk '{print NR".", substr($0, 6)}'
  echo ""
  printf "${CYAN}00 - Выход в главное меню${NC}\n"
  echo ""
  read -p "Выберите файл для замены: " choice
  choice=$(echo "$choice" | tr -d ' ')
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
  printf "${CYAN}00 - Выход в главное меню${NC}\n"
  echo ""
  printf "${GREEN}Выбран $mtdName для замены${NC}\n"
  printf "${RED}Внимание, загрузчик не перезаписывается!${NC}\n"
  read -p "Выберите, какой раздел перезаписать (например для mtd2 это 2): " choice
  choice=$(echo "$choice" | tr -d ' ')
  if [ "$choice" = "00" ]; then
    main_menu
  fi
  selected_mtd=$(echo "$output" | awk -v i=$choice 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
  echo ""
  read -r -p "Перезаписать раздел mtd$choice.$selected_mtd вашим $mtdName? (y/n) " item_rc1
  item_rc1=$(echo "$item_rc1" | tr -d ' ')
  case "$item_rc1" in
  y | Y)
    sleep 2
    echo ""
    dd if=$mtdFile of=/dev/mtdblock$choice
    wait
    second_mtd=$(echo "$output" | grep -v "^mtd$choice" | awk -v name=$selected_mtd 'BEGIN{IGNORECASE=1} $0 ~ name {print substr($0, index($0,$4)); exit}' | grep -oP '(?<=\").*(?=\")')
    if [ -n "$second_mtd" ]; then
      echo ""
      printf "${CYAN}"
      read -r -p "Обнаружен второй раздел $second_mtd, также перезаписать? (y/n) " item_rc2
      item_rc2=$(echo "$item_rc2" | tr -d ' ')
      printf "${NC}"
      case "$item_rc2" in
      y | Y)
        second_choice=$(echo "$output" | awk -v name=$second_mtd 'BEGIN{IGNORECASE=1} $0 ~ name {print substr($1, 4)}')
        sleep 2
        echo ""
        dd if=$mtdFile of=/dev/mtdblock$second_choice
        wait
        ;;
      n | N)
        echo ""
        ;;
      *) ;;
      esac
    fi
    ;;
  n | N)
    echo ""
    ;;
  esac
  echo ""
  successful_message "Раздел успешно перезаписан"
  printf "${NC}"
  read -r -p "Перезагрузить роутер? (y/n) " item_rc3
  item_rc3=$(echo "$item_rc3" | tr -d ' ')
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
}

main_menu
