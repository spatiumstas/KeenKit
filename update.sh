#!/bin/sh
printf "\033c"
files=$(find /opt -name '*.bin')
count=$(echo "$files" | wc -l)

if [ $count -eq 0 ]; then
    echo "Прошивка не найдена, скопируйте файл обновления в корень встроенного хранилище роутера"
exit 1
fi
    echo "Выберете файл обновления (от 1 до $count):"
    echo "$files"
    read choice

if [ $choice -lt 1 ] || [ $choice -gt $count ]; then
    echo "Неверный выбор файла"
exit 1
fi

Firmware=$(echo "$files" | awk "NR==$choice")
FirmwareName=$(basename "$Firmware")
    echo ""
    echo "Выбран - $FirmwareName"
    echo ""
    mtdSlot="$(grep -w '/proc/mtd' -e 'Firmware_1')"
    echo "$mtdSlot"
    echo ""
    echo ""
    result=$(echo "$mtdSlot" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    echo "Firmware_1 на mtd$result разделе, обновляю..."
    dd if=$Firmware of=/dev/mtdblock$result
    wait
    echo ""
    echo ""
    mtdSlot2="$(grep -w '/proc/mtd' -e 'Firmware_2')"
    echo "$mtdSlot2"
    echo ""
    echo ""
    result2=$(echo "$mtdSlot2" | grep -oP '.*(?=:)' | grep -oE '[0-9]+')
    echo "Firmware_2 на mtd$result2 разделе, обновляю..."
    dd if=$Firmware of=/dev/mtdblock$result2
    wait
    echo ""
    echo ""
    read -p "Удалить файл обновления? (y/n) " item_rc1
    case "$item_rc1" in
y|Y) echo ""
rm $Firmware
wait
;;
n|N) echo ""
;;
*)
esac
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
