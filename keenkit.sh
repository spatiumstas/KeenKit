#!/bin/sh

main_menu() {
printf "\033c"
echo "KeenKit v1.1 by spatiumstas"
echo ""
echo "1. Обновить прошивку"
echo "2. Бекап разделов"
echo "3. Бекап Entware"
echo "0. Выход"
echo ""
read -p "Выберите действие (от 0 до 3): " choice

case "$choice" in
1) firmware_update ;;
2) backup_blocks ;;
3) backup_entware ;;
0) exit ;;
*) echo "Неверный выбор. Попробуйте снова." ; sleep 2 ; main_menu ;;
esac
}

firmware_update() {
files=$(find /opt -name '*.bin')
count=$(echo "$files" | wc -l)

if [ $count -eq 0 ]; then
echo "Прошивка не найдена, скопируйте файл обновления в корень встроенного хранилище роутера"
sleep 2
main_menu
fi
echo ""
echo ""

echo "$files" | awk '{print NR, $0}'
echo ""
echo "Выберете файл обновления (от 1 до $count):"

read choice

if [ $choice -lt 1 ] || [ $choice -gt $count ]; then
echo "Неверный выбор файла"
sleep 2
main_menu
fi

Firmware=$(echo "$files" | awk "NR==$choice")
FirmwareName=$(basename "$Firmware")
    echo ""
    echo "Выбран - $FirmwareName"
    echo ""
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
    read -p "Удалить файл обновления? (y/n) " item_rc1
    case "$item_rc1" in
y|Y)
rm $Firmware
wait
;;
n|N) echo ""
;;
*)
esac

    read -p "Перезагрузить роутер? (y/n) " item_rc2
case "$item_rc2" in
y|Y) echo ""
reboot
;;
n|N) echo ""
;;
*)
esac

sleep 3
main_menu
}

backup_entware(){
output=$(mount)
filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
echo ""
echo ""
echo "Доступные накопители:"
echo "0. Встроенное хранилище (может не хватить места)"
echo "$filtered_output" | awk '{print NR, $0}'
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

sleep 3
main_menu
}

backup_blocks() {
output=$(mount)
filtered_output=$(echo "$output" | grep "tmp/mnt/" | awk '{print $3}')
echo ""
echo "Доступные накопители:"
echo "0. Встроенное хранилище (может не хватить места)"
echo "$filtered_output" | awk '{print NR, $0}'
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
echo "1 Бекап всех разделов"
echo "$output" | awk 'NR>1 {print NR, $0}'
echo ""
mkdir -p /$selected_drive/mtd_backup
read -p "Выберите раздел: " choice
if [ "$choice" -eq 1 ]; then 
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
do
echo "Копирую mtd$i.bin..."   
cat /dev/mtdblock$i > /$selected_drive/mtd_backup/mtd$i.bin
done
echo ""
echo "Бекап успешно выполнен"
else
selected_mtd=$(echo "$output" | sed -n "${choice}p")
echo "Выбран $selected_mtd"
selected_mtd_cut=$(echo "$selected_mtd" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')

echo "Бекап mtd$selected_mtd_cut в $selected_drive"
echo ""
dd if=/dev/mtd$selected_mtd_cut of=/$selected_drive/mtd_backup/mtd$selected_mtd_cut.bin
wait
echo ""
echo ""
echo "Бекап успешно выполнен"
fi
sleep 3
main_menu
}

main_menu
