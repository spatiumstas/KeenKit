#! /bin/sh

if test $(find /opt -name '*update*'); then
   Firmware=$(find /opt -name '*update*')
   FirmwareName=$(basename -- "$Firmware")
   md5=$(md5sum $Firmware)
    echo "Прошивка $FirmwareName найдена."
    echo "Контрольная сумма - $md5"
REBOOTCONFIRM(){
    echo "" 
    echo -n "Контрольная сумма совпадает? (y/n) " 
 
    read item_rc 
    case "$item_rc" in 
    y|Y) echo ""
    echo "Обновление роутера...."
    echo ""
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
    echo "Проверяю раздел Firmware_1"

if  grep -w '/proc/mtd' -e 'Firmware_1' | grep mtd3; then
    echo "Firmware_1 на mtd3 разделе" 
    echo "Oбновление Firmware_1"
    dd if=$Firmware of=/dev/mtdblock3
    wait
else 
    echo "Firmware_1 на mtd5 разделе"
    echo "Oбновление Firmware_1"
    dd if=$Firmware of=/dev/mtdblock5
    wait
fi
    echo "Oбновление Firmware_2"
    dd if=$Firmware of=/dev/mtdblock13
    wait
    echo "Удаляю файл обновления"
    rm $Firmware
    wait
    echo ""
    echo "Перезагрузка роутера..."
    reboot
else
   echo "Файл обновления не найден в /opt"
   echo "Скопируйте файл обновления на встроенное хранилище роутера."
fi
