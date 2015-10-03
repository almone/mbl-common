#Подготовка образа готовой системы.

# Склеивание user-space и kernel-space частей #

Понадобится любой SATA-диск с объёмом более пяти гигабайт. На него будет установлен образ будущей системы Debian Wheezy, а сам диск после этих манипуляций заменит заводской, который в этот момент у вас подключен в MBL. Если у вас стальные яйца, то вы, конечно, можете сразу использовать заводской диск от MBL, но с первой попытки у вас скорее всего ничего не выйдет, а откатываться будет не к чему.

Все действия будут проводится на Linux ПК. Если у вас линукса на ПК нет, то скачайте [CD Ubuntu ](http://www.ubuntu.com/download/desktop) и установите его как Live-систему на флешку с помощью Universal [USB Installer](http://www.pendrivelinux.com/universal-usb-installer-easy-as-1-2-3/). Для удобства можете сразу положить на флешку архивы с подготовленными на предыдущих шагах user-space и kernel-space-частями и скриптик debricker.sh. Инструкцию по разборке MBL, переразбивке диска и скрипт можно найти [здесь](http://tandp.subankulov.com/archives/462).

На Linux ПК выполняем [процедуры](http://tandp.subankulov.com/archives/462) по восстановлению образа диска, после которых диск будет иметь ровно такой же вид, как в MBL с завода. Далее необходимо смонтировать RAID1, который в будущем будет корневой файловой системой для Debian Wheezy на MBL. Я буду подразумевать, что мы работаем с диском /dev/sda.

```
mdadm --create /dev/md0 --verbose --metadata=0.9 --raid-devices=2 --level=raid1 --run /dev/sda1 missing
mdadm /dev/md0 --add --verbose /dev/sda2
mdadm --wait /dev/md0
mkfs.ext3 -c -b 4096 /dev/md0
mkdir /mnt/md0
mount /dev/md0 /mnt/md0
```

`/mnt/md0` — это будущая корневая файловая система для нашего устройства. Распаковываем на неё:

  * user-space часть из [подготовленного](http://code.google.com/p/mbl-common/wiki/PureDebianUserSpace) ранее  архива debints.tgz,
  * в папку /mnt/md0/boot три файла, отвечающие (упрощаем) за kernel-space часть, вы их тоже [подготовили](http://code.google.com/p/mbl-common/wiki/PureDebianKernelSpace) ранее: boot.scr, uImage и apollo3g.dtb.

Всё готово. Остаётся размонтировать /dev/md0:

```
umount /mnt/md0
mdadm --stop /dev/md0
```

и выполнить "магию" по изменению big-endian на little-endian для сигнатур половинок будущего RAID1-массива. Для этого необходимо "выдрать" бинарник `swap` из скрипта debricker.sh или взять готовый [отсюда](http://bijutiva.ru/wp-content/upload/wd/swap.zip).

```
./swap /dev/sda1 
./swap /dev/sda2 
```

Подготовка Debian Wheezy завершена. Осталось подключить подготовленный диск вместо штатного и перекрестить пальцы. [Здесь](http://pastebin.com/TiLqV6mW) приведён лог загрузки для случая, когда всё заработало.