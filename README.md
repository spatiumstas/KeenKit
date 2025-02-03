# KeenKit
### Многофункциональный скрипт, упрощающий взаимодействие с роутером на базе KeeneticOS

![image_2025-02-02_17-32-41](https://github.com/user-attachments/assets/315deac4-6144-48fc-b8d3-b1107b4b1ba6)

# Установка
1. Подключиться по `SSH` к [Entware](https://keen-prt.github.io/wiki/helpful/entware)

2. Установить скрипт
```
opkg update && opkg install curl && curl -L -s "https://raw.githubusercontent.com/spatiumstas/KeenKit/main/install.sh" > /tmp/install.sh && sh /tmp/install.sh
```
Запуск через:
>keenkit, KeenKit или /opt/keenkit.sh

#  Описание команд
- ## **Обновить прошивку**
    - Ищет файл с расширением .bin на встроенном/внешнем накопителе с последующей установкой на Firmware разделы
- ## **Бэкап разделов**
    - Бэкапит раздел/ы на выбранный накопитель
- ## **Бэкап Entware**
    - Создаёт полный бэкап накопителя, из которого запущен скрипт. Его можно использовать как установочный при [новой установке](https://keen-prt.github.io/wiki/helpful/entware).
- ## **Заменить раздел**
    - Замена раздела системы на раздел, выбранный пользователем
- ## **OTA Update**
    - Онлайн обновление/даунгрейд прошивки
- ## **Заменить сервисные данные**
    - Создаёт новый U-Config с изменёнными сервисными данными и перезаписывает текущий
