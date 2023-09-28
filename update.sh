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

md5=$(md5sum "$Firmware")
    echo "Контрольная сумма - $md5"

REBOOTCONFIRM(){
    echo ""
    read -p "Контрольная сумма совпадает? (y/n) " item_rc
case "$item_rc" in
    y|Y) echo ""
    ;;
    n|N) echo ""
    echo "Удаляю файл обновления"
    echo "Скопируйте ещё раз файл обновления на встроенное хранилище"
    echo ""
    rm $Firmware
    exit 0
    ;;
*) echo "Вы ничего не ввели..."
    REBOOTCONFIRM
    ;;
    esac
}

REBOOTCONFIRM

    echo ""
if grep -w '/proc/mtd' -e 'Firmware_1' | grep mtd3; then
    echo ""
    echo "Firmware_1 на mtd3 разделе"
    echo ""
    echo "Oбновление Firmware_1"
    dd if=$Firmware of=/dev/mtdblock3
    wait
else
    echo "Firmware_1 на mtd5 разделе"
    echo "Oбновление Firmware_1"
    dd if=$Firmware of=/dev/mtdblock5
    wait
fi
    echo ""
    echo "Oбновление Firmware_2"
    dd if=$Firmware of=/dev/mtdblock13
    wait
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
