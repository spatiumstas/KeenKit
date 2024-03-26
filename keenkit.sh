#!/bin/sh
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'
USER="spatiumstas"

main_menu() {
  printf "\033c"
  printf "${CYAN}KeenKit v1.5.4 by $USER${NC}\n"
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
  1) firmware_update ;;
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

script_update() {
  REPO="KeenKit"
  SCRIPT="keenkit.sh"
  TMP_DIR="/tmp"

  if ! opkg list-installed | grep -q "^curl"; then
    echo "Пакет curl не найден, устанавливаем..."
    opkg install curl
  fi

  curl -L -s "https://raw.githubusercontent.com/spatiumstas/KeenKit/main/keenkit.sh" --output $TMP_DIR/$SCRIPT

  if [ -f "$TMP_DIR/$SCRIPT" ]; then
    mv "$TMP_DIR/$SCRIPT" "/opt/$SCRIPT"
    chmod +x /opt/$SCRIPT
    echo ""
    printf "${GREEN}"
    echo -e "\n+--------------------------------------------------------------+"
    echo -e "|                 Скрипт успешно обновлён                      |"
    echo -e "+--------------------------------------------------------------+\n"
    printf "${NC}"
  else
    printf "${RED}Ошибка при скачивании скрипта.${NC}\n"
  fi
  sleep 2
  /opt/$SCRIPT
}

ota_update() {
  REPO="osvault"

  if ! opkg list-installed | grep -q "^curl"; then
    echo "${RED}Пакет curl не найден, устанавливаем...${NC}"
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
      printf "${RED}Не удалось загрузить файл $FILE.${NC}\n"
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
      printf "${RED}MD5 хеш не совпадает. Убедитесь что в ОЗУ свободно более 30МБ${NC}\n"
      echo "Ожидаемый - $MD5SUM"
      echo "Фактический - $FILE_MD5SUM"

      exit 1
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
      printf "${GREEN}"
      echo -e "\n+--------------------------------------------------------------+"
      echo -e "|                 Прошивка успешно обновлена                   |"
      echo -e "+--------------------------------------------------------------+\n"
      printf "${NC}"
      sleep 1
      ;;
    esac
  fi
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

update_firmware() {
  local firmware=$1
  local mtdblock=$2

  echo "Firmware на mtd${mtdblock} разделе, обновляю..."
  dd if=$firmware of=/dev/mtdblock$mtdblock
  wait
}

firmware_update() {
  output=$(mount)
  filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
  echo ""
  echo "Доступные накопители:"
  echo "0. Встроенное хранилище"
  if [ -n "$filtered_output" ]; then
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
  fi
  echo ""
  read -p "Выберите накопитель с размещённым файлом обновления: " choice
  choice=$(echo "$choice" | tr -d ' ')

  if [ "$choice" = "0" ]; then
    selected_drive="/opt"
  else
    selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
  fi

  files=$(find $selected_drive -name '*.bin' -size +10M)
  count=$(echo "$files" | wc -l)

  if [ -z "$files" ]; then
    echo ""
    printf "${RED}Файл обновления не найден на встроенном хранилище${NC}\n"
    echo ""
    echo "Возврат в главное меню..."
    sleep 3
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
    update_firmware $Firmware $result
    echo ""
    mtdSlot2="$(grep -w '/proc/mtd' -e 'Firmware_2')"
    result2=$(echo "$mtdSlot2" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    update_firmware $Firmware $result2
    printf "${GREEN}"
    echo -e "\n+--------------------------------------------------------------+"
    echo -e "|                 Прошивка успешно обновлена                   |"
    echo -e "+--------------------------------------------------------------+\n"
    printf "${NC}"
    echo ""
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
  filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
  echo -e "\n"
  echo "Доступные накопители:"
  echo "0. Встроенное хранилище (может не хватить места)"
  if [ -n "$filtered_output" ]; then
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
  fi
  echo -e "\n"
  read -p "Выберите накопитель: " choice
  choice=$(echo "$choice" | tr -d ' ')

  if [ "$choice" = "0" ]; then
    selected_drive="/opt"
  else
    selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
  fi

  output=$(cat /proc/mtd)
  echo -e "\n"
  printf "${GREEN}Доступные разделы:${NC}\n"
  echo "$output" | awk 'NR>1 {print $0}'
  echo -e "\n"
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
  echo -e "\n"
  printf "${GREEN}"
  echo -e "\n+--------------------------------------------------------------+"
  echo -e "    Раздел успешно скопирован в $folder_path"
  echo -e "+--------------------------------------------------------------+\n"
  sleep 2
  printf "${NC}"
  echo "Возврат в главное меню..."
  sleep 2
  main_menu
}

backup_entware() {
  output=$(mount)
  filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
  echo ""
  echo "Доступные накопители:"
  echo "0. Встроенное хранилище (может не хватить места)"
  if [ -n "$filtered_output" ]; then
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
  fi
  echo ""
  read -p "Выберите накопитель: " choice
  choice=$(echo "$choice" | tr -d ' ')

  if [ "$choice" = "0" ]; then
    selected_drive="/opt"
  else
    selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
    if [ -z "$selected_drive" ]; then
      echo "Недопустимый выбор. Пожалуйста, попробуйте еще раз."
      return 1
    fi
  fi

  echo "Запускаю бекап..."
  tar cvzf "$selected_drive/mipsel_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz" -C /opt .
  wait
  echo ""
  printf "${GREEN}"
  echo -e "\n+--------------------------------------------------------------+"
  echo -e "|                 Бекап успешно выполнен                       |"
  echo -e "+--------------------------------------------------------------+\n"
  sleep 2
  printf "${NC}"
  echo "Возврат в главное меню..."
  sleep 2
  main_menu
}

rewrite_block() {
  output=$(mount)
  filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
  echo ""
  echo "Доступные накопители:"
  echo "0. Встроенное хранилище"
  if [ -n "$filtered_output" ]; then
    echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
  fi
  echo ""
  read -p "Выберите накопитель с размещённым файлом: " choice
  choice=$(echo "$choice" | tr -d ' ')

  if [ "$choice" = "0" ]; then
    selected_drive="/opt"
  else
    selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
  fi
  files=$(find $selected_drive -name '*.bin')
  count=$(echo "$files" | wc -l)
  if [ -z "$files" ]; then
    echo ""
    printf "${RED}Bin файл не найден в выбранном хранилище${NC}\n"
    echo "Возврат в главное меню..."
    sleep 3
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
  printf "${GREEN}"
  echo -e "\n+--------------------------------------------------------------+"
  echo -e "|                 Раздел успешно перезаписан                   |"
  echo -e "+--------------------------------------------------------------+\n"
  sleep 1
  printf "${NC}"
  read -r -p "Перезагрузить роутер? (y/n) " item_rc2
  item_rc2=$(echo "$item_rc2" | tr -d ' ')
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

main_menu
