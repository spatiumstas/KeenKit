[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.donationalerts.com/r/spatiumstas)

# Установка
1. Через Telnet/SSH попасть в установленный Entware
```   
exec sh
```   
2. Установить скрипт
```
opkg update && opkg install curl && curl -L -s "https://raw.githubusercontent.com/spatiumstas/KeenKit/main/install.sh" > /tmp/install.sh && sh /tmp/install.sh
```
Запуск через:
>keenkit, KeenKit или /opt/keenkit.sh

#  Описание команд
- ## **Обновить прошивку**
    - Ищет файл с расширением .bin на встроенном/внешнем накопителе с последующей установкой на разделы Firmware или Firmware_1/Firmware_2
- ## **Бэкап разделов**
    - Бэкапит выбранный раздел на flash памяти роутера
- ## **Бэкап Entware**
    - Создаёт полный бэкап накопителя, позволяющий восстановиться из него
- ## **Заменить раздел**
    - Заменяет содержимое раздела на flash памяти роутера выбранным .bin файлом
- ## **OTA Update**
    - Онлайн обновление/даунгрейд портированных прошивок Keenetic

1123
![image](https://github.com/spatiumstas/KeenKit/assets/79056064/431ef425-60c8-4d3a-80df-dadbf1d0608c)
