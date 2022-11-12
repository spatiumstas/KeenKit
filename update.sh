#! /bin/sh

if test $(find /opt -name '*Sedy*'); then
   Firmware=$(find /opt -name '*Sedy*')
   FirmwareName=$(basename -- "$Firmware")
   md5=$(md5sum $Firmware)
    echo "Прошивка $FirmwareName найдена."
    echo "Контрольная сумма - $md5"
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
    rm $Firmware
    wait
    echo "Прошивка удалена"
    echo "Перезагрузка роутера"
    reboot
else
   echo "Прошивка не найдена в /opt"
fi