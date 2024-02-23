#!/bin/sh

main_menu() {
printf "\033c"
printf "\033[1;36mKeenKit v1.5 by spatiumstas\033[0m\n"
echo ""
echo "1. Обновить прошивку"
echo "2. Бекап разделов"
echo "3. Бекап Entware"
echo "4. Заменить раздел"
echo "5. OTA Update (beta)"
echo ""
echo "00. Выход"
echo "99. Обновить скрипт"
echo ""
read -p "Выберите действие: " choice

case "$choice" in
1) firmware_update ;;
2) backup_block ;;
3) backup_entware ;;
4) rewrite_block ;;
5) ota_update ;;
99) script_update ;;
00) exit ;;
*) echo "Неверный выбор. Попробуйте снова." ; sleep 5 ; main_menu ;;
esac
}

script_update(){
    USER="spatiumstas"
    REPO="KeenKit"
    SCRIPT="keenkit.sh"
    TMP_DIR="/tmp"
    curl -L -s "https://raw.githubusercontent.com/spatiumstas/KeenKit/main/keenkit.sh" --output $TMP_DIR/$SCRIPT

    if [ -f "$TMP_DIR/$SCRIPT" ]; then
        mv "$TMP_DIR/$SCRIPT" "/opt/$SCRIPT"
        chmod +x /opt/$SCRIPT
        echo ""
        printf "\033[1;32mСкрипт успешно обновлен!\033[0m\n"
    else
        printf "\033[1;31mОшибка при скачивании скрипта.\033[0m\n"
    fi
    sleep 2
    /opt/$SCRIPT
}

ota_update(){
USER="spatiumstas"
REPO="osvault"

DIRS=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}')

echo ""
printf "\033[1;32mДоступные модели:\033[0m\n"
i=1
IFS=$'\n' 
for DIR in $DIRS; do
    printf "\033[1;36m$i. $DIR\033[0m\n"
    i=$((i+1))
done

echo ""
read -p "Выберите модель: " DIR_NUM
DIR=$(echo "$DIRS" | sed -n "${DIR_NUM}p")

BIN_FILES=$(curl -s "https://api.github.com/repos/$USER/$REPO/contents/$DIR" | grep -Po '"name":.*?[^\\]",' | awk -F'"' '{print $4}' | grep ".bin")

if [ -z "$BIN_FILES" ]
then
    printf "\033[1;31mВ директории $DIR нет файлов.\033[0m\n"
else
    printf "\n\033[1;32mПрошивки для $DIR:\033[0m\n"
    i=1
    for FILE in $BIN_FILES; do
        printf "\033[1;36m$i. $FILE\033[0m\n"
        i=$((i+1))
    done

    echo ""
    read -p "Выберите прошивку: " FILE_NUM
    FILE=$(echo "$BIN_FILES" | sed -n "${FILE_NUM}p") 

    curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$DIR/$FILE" --output /tmp/$FILE
    echo ""

    if [ -f "/tmp/$FILE" ]; then
        printf "\033[1;32mФайл $FILE успешно скачан.\033[0m\n"
    else
        printf "\033[1;31mФайл $FILE не был скачан/найден.\033[0m\n"
        exit 1
    fi
    curl -L -s "https://raw.githubusercontent.com/$USER/$REPO/master/$DIR/md5sum" --output /tmp/md5sum

    MD5SUM=$(grep "$FILE" /tmp/md5sum | awk '{print $1}')

    FILE_MD5SUM=$(md5sum /tmp/$FILE | awk '{print $1}')

    if [ "$MD5SUM" == "$FILE_MD5SUM" ]; then
        printf "\033[1;32mMD5 хеш совпадает.\033[0m\n"
    else
        printf "\033[1;31mMD5 хеш не совпадает. Убедитесь что в ОЗУ есть свободное место\033[0m\n"
        echo "Ожидаемый - $MD5SUM"
        echo "Фактический - $FILE_MD5SUM"

        exit 1
    fi
    echo ""
    Firmware="/tmp/$FILE"
    FirmwareName=$(basename "$Firmware")
    read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
    case "$item_rc1" in
        y|Y) 
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
            printf "\033[1;32m"
            printf "\n"
            printf "---------------------------------------------------------------\n"
            printf "              Прошивка успешно обновлена\n"
            printf "---------------------------------------------------------------\n"
            printf "\n"
            printf "\033[0m"
            sleep 2
            ;;
    esac
fi
read -p "Перезагрузить роутер? (y/n) " item_rc1
case "$item_rc1" in
y|Y) echo ""
reboot
;;
n|N) echo ""
;;
*)
esac
echo "Возврат в главное меню через 2 секунды..."
sleep 2
main_menu
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
read -p "Выберите накопитель с размещённым файлом обновления (.bin): " choice

if [ "$choice" -eq 0 ]; then
selected_drive="/opt"
else
selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
fi

files=$(find $selected_drive -name '*.bin')
count=$(echo "$files" | wc -l)

if [ -z "$files" ]; then
echo ""    
printf "\033[1;31mПрошивка формата .bin не найдена, скопируйте файл на встроенного хранилище роутера\033[0m\n"
echo ""  
echo "Возврат в главное меню через 7 секунд..."
sleep 7
main_menu
fi
echo ""
echo "$files" | awk '{print NR".", substr($0, 6)}'
echo ""
printf "\033[0;36m"
echo "00 - Выход в главное меню"
echo ""
printf "\033[0m"
read -p "Выберите файл обновления (от 1 до $count): " choice
if [ "$choice" -eq 00 ]; then
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
printf "\033[1;32m"
read -p "Выбран $FirmwareName для обновления, всё верно? (y/n) " item_rc1
printf "\033[0m"
case "$item_rc1" in
y|Y) echo ""
mtdSlot="$(grep -w '/proc/mtd' -e 'Firmware_1')"
    echo "$mtdSlot"
    result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    echo "Firmware_1 на mtd$result разделе, обновляю..."
    dd if=$Firmware of=/dev/mtdblock$result
    wait
    echo ""
    mtdSlot2="$(grep -w '/proc/mtd' -e 'Firmware_2')"
    echo "$mtdSlot2"
    result2=$(echo "$mtdSlot2" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    echo "Firmware_2 на mtd$result2 разделе, обновляю..."
    dd if=$Firmware of=/dev/mtdblock$result2
    wait
printf "\033[1;32m"
echo ""
echo ------------------------------------------------------------------------
echo               "Прошивка успешно обновлена"
echo ------------------------------------------------------------------------
echo ""
sleep 2
printf "\033[0m"
    echo ""
    read -p "Удалить файл обновления? (y/n) " item_rc2
    case "$item_rc2" in
y|Y)
rm $Firmware
wait
sleep 2
;;
n|N) echo ""
;;
*)
esac

    read -p "Перезагрузить роутер? (y/n) " item_rc3
case "$item_rc3" in
y|Y) echo ""
reboot
;;
n|N) echo ""
;;
*)
esac
echo "Возврат в главное меню через 2 секунды..."
sleep 2
main_menu
;;
n|N) main_menu
;;
*)
esac
}

backup_block() {
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

if [ "$choice" -eq 0 ]; then
selected_drive="/opt"
else
selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
fi

output=$(cat /proc/mtd)
echo ""
printf "\033[1;32m"
echo "Доступные разделы:"
printf "\033[0m"
echo "$output" | awk 'NR>1 {print $0}'
echo ""
printf "\033[0;36m"
echo "00 - Выход в главное меню"
echo "99 - Бекап всех разделов"
echo ""
printf "\033[0m"
folder_path=$selected_drive/backup$(date +%Y-%m-%d_%H-%M-%S)
read -p "Выберите цифру раздела (например для mtd2 это 2): " choice 
if [ "$choice" -eq 00 ]; then
    main_menu
fi
mkdir -p $folder_path
if [ "$choice" -eq 99 ]; then
output_all_mtd=$(cat /proc/mtd | grep -c "mtd")
for i in $(seq 0 $(($output_all_mtd-1)))
do
    mtd_name=$(echo "$output" | awk -v i=$i 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
    echo "Копирую mtd$i.$mtd_name.bin..."   
    cat /dev/mtdblock$i > $folder_path/mtd$i.$mtd_name.bin
done

else
selected_mtd=$(echo "$output" | awk -v i=$choice 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
echo "Выбран mtd$choice.$selected_mtd.bin, копирую..."
echo ""
dd if=/dev/mtd$choice of=$folder_path/mtd$choice.$selected_mtd.bin
wait
fi
echo ""
printf "\033[1;32m"
echo ------------------------------------------------------------------------
echo               "Раздел успешно скопирован в $folder_path"
echo ------------------------------------------------------------------------
echo ""
sleep 2
printf "\033[0m"
echo "Возврат в главное меню через 5 секунд..."
sleep 5
main_menu
}

backup_entware(){
output=$(mount)
filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
echo ""
echo "Доступные накопители:"
echo "0. Встроенное хранилище (может не хватить места)"
if [ -n "$filtered_output" ]; then
echo "$filtered_output" | awk '{print NR".", $0}'
fi
echo ""
read -p "Выберите накопитель: " choice

if [ "$choice" -eq 0 ]; then 
selected_drive="/opt" 
else
selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
fi

echo "Запускаю бекап..."
tar cvzf "$selected_drive/mipsel_backup.tar.gz" -C /opt .
wait
echo ""
printf "\033[1;32m"
echo ------------------------------------------------------------------------
echo               "Бекап успешно выполнен"
echo ------------------------------------------------------------------------
echo ""
sleep 2
printf "\033[0m"
echo "Возврат в главное меню через 5 секунд..."
sleep 5
main_menu
}

rewrite_block(){
output=$(mount)
filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
echo ""
echo "Доступные накопители:"
echo "0. Встроенное хранилище"
if [ -n "$filtered_output" ]; then
echo "$filtered_output" | awk '{print NR".", substr($0, 10)}'
fi
echo ""
read -p "Выберите накопитель с размещённым файлом (.bin): " choice

if [ "$choice" -eq 0 ]; then
selected_drive="/opt"
else
selected_drive=$(echo "$filtered_output" | sed -n "${choice}p")
fi
files=$(find $selected_drive -name '*.bin')
count=$(echo "$files" | wc -l)
if [ -z "$files" ]; then
echo ""    
printf "\033[1;31mBin файл не найден в выбранном хранилище\033[0m\n"
echo "Возврат в главное меню через 5 секунд..."
sleep 5
main_menu
fi
echo "Доступные файлы:"
echo "$files" | awk '{print NR".", substr($0, 6)}'
echo ""
printf "\033[0;36m"
echo "00 - Выход в главное меню"
echo ""
printf "\033[0m"
read -p "Выберите файл для замены: " choice
if [ "$choice" -eq 00 ]; then
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
echo ""
output=$(cat /proc/mtd)
echo "$output" | awk 'NR>1 {print $0}'
echo "00 - Выход в главное меню"
echo ""
echo "Выбран - $mtdName"
echo "Внимание! Загрузчик не перезаписывается!"
read -p "Выберите, какой раздел перезаписать выбранным файлом (например для mtd2 это 2): " choice 
if [ "$choice" -eq 00 ]; then
    main_menu
fi
selected_mtd=$(echo "$output" | awk -v i=$choice 'NR==i+2 {print substr($0, index($0,$4))}' | grep -oP '(?<=\").*(?=\")')
echo ""
echo "Выбран mtd$choice.$selected_mtd для замены"
read -p "Перезаписать раздел mtd$choice.$selected_mtd вашим $mtdName? (y/n) " item_rc1
    case "$item_rc1" in
y|Y)
sleep 2
echo ""
dd if=$mtdFile of=/dev/mtdblock$choice
wait
sleep 2
echo ""
printf "\033[1;32m"
echo ------------------------------------------------------------------------
echo               "Раздел успешно перезаписан"
echo ------------------------------------------------------------------------
echo ""
sleep 2
printf "\033[0m"
read -p "Перезагрузить роутер? (y/n) " item_rc2
case "$item_rc2" in
y|Y) echo ""
reboot
;;
n|N) echo ""
;;
*)
esac
echo "Возврат в главное меню через 3 секунды..."
sleep 3
main_menu
;;
n|N) main_menu
;;
*)
esac
}

main_menu
