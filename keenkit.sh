#!/bin/sh

main_menu() {
printf "\033c"
echo "KeenKit v1.4 by spatiumstas"
echo ""
echo "1. Обновить прошивку"
echo "2. Бекап разделов"
echo "3. Бекап Entware"
echo "4. Заменить раздел"
echo ""
echo "0. Выход"
echo ""
read -p "Выберите действие (от 0 до 4): " choice

case "$choice" in
1) firmware_update ;;
2) backup_block ;;
3) backup_entware ;;
4) rewrite_block ;;
0) exit ;;
*) echo "Неверный выбор. Попробуйте снова." ; sleep 5 ; main_menu ;;
esac
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
echo "Прошивка формата .bin не найдена, скопируйте файл на встроенного хранилище роутера"
echo ""  
echo "Возврат в главное меню через 7 секунд..."
sleep 7
main_menu
fi
echo ""
echo "$files" | awk '{print NR".", substr($0, 6)}'
echo "00 - Выход в главное меню"
echo ""
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
read -p "Выбран - $FirmwareName для обновления, всё верно? (y/n) " item_rc1
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
    echo ""
    read -p "Удалить файл обновления? (y/n) " item_rc2
    case "$item_rc2" in
y|Y)
rm $Firmware
wait
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
echo ""
echo "$output" | awk 'NR>1 {print $0}'
echo "00 - Выход в главное меню"
echo "99 - Бекап всех разделов"
echo ""
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
echo "Бекап успешно выполнен в $folder_path"
echo ""
sleep 2
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

echo "Выполняю бекап..."
tar cvzf "$selected_drive/mipsel_backup.tar.gz" -C /opt .
wait
echo ""
echo "Бекап успешно выполнен"
echo "Возврат в главное меню через 7 секунд..."
sleep 7
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
echo "Bin файл не найден в выбранном хранилище"
echo "Возврат в главное меню через 5 секунд..."
sleep 5
main_menu
fi
echo "Доступные файлы:"
echo "$files" | awk '{print NR".", substr($0, 6)}'
echo ""
echo "00 - Выход в главное меню"
read -p "Выберите файл для замены (от 1 до $count): " choice
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
echo "Раздел успешно перезаписан"
echo ""
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
