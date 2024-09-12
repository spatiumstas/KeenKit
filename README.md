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
- ## **Заменить сервисные данные**
    - Создаёт и перезаписывает новый U-Config с изменёнными сервисными данными


![image](https://github.com/user-attachments/assets/8fda7d7e-0e9c-4991-a2bb-51e2aea1d8f0)

