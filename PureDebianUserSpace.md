#Подготовка User Space.

# Подготовка user space для Debian Wheezy #

Выполняется на работающем MBL по [этому](http://www.debian.org/releases/stable/i386/apds03.html.en) изюмительному мануалу. Устанавливаем debootstrap (клянусь, это — единственный пакет, который придётся ставить в хост систему. Учитывая, что он представляет собой лишь набор скриптов прошивке мы не навредим) и подготавливаем образ будущей системы:

```
wget http://mbl-common.googlecode.com/svn/chroot-install/debootstrap_1.0.10lenny1_all.deb
dpkg -i ./debootstrap_1.0.10lenny1_all.deb
ln -sf /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/wheezy
debootstrap --arch powerpc wheezy /DataVolume/debinst http://ftp.us.debian.org/debian
```

Далее можно «провалиться» в получившуюся среду и донастроить её:

```
mount -o bind /proc /DataVolume/debinst/proc
LANG=C.UTF-8 chroot /DataVolume/debinst /bin/bash
```

В частности, создать node'ы ключевых устройств:

```
apt-get install makedev
cd /dev
MAKEDEV generic
```

Далее лучше пока воспользоваться деревом устройств хост системы и продолжить настройку с ними:

```
exit
mount -o bind /dev /DataVolume/debinst/dev
cp /etc/fstab /DataVolume/debinst/etc/fstab
cp /etc/network/interfaces /DataVolume/debinst/etc/network/interfaces
cp /etc/hostname /DataVolume/debinst/etc/hostname
cp /etc/hosts /DataVolume/debinst/etc/hosts
echo nameserver 8.8.8.8 > /DataVolume/debinst/etc/resolv.conf
echo deb http://security.debian.org/ wheezy/updates main >> /DataVolume/debinst/etc/apt/sources.list
echo deb-src http://security.debian.org/ wheezy/updates main >> /DataVolume/debinst/etc/apt/sources.list
chroot /DataVolume/debinst
```

Осталось подправить в будущей системе часовой пояс, выбрать правильную locale и установить ssh, который должен будет работать сразу после установки:

```
aptitude install locales
dpkg-reconfigure locales
dpkg-reconfigure tzdata
aptitude install ssh
passwd
```

Опционально можно установить пакеты `ethtool ifplugd ifupdown module-init-tools ntp` и изменить `default runlevel` в `/etc/inittab`, но это уже мелочи.
User-space часть готова. Осталось упаковать и перенести её на место назначения:

```
/etc/init.d/ssh stop
aptitude clean
exit
umount /DataVolume/debinst/dev
umount /DataVolume/debinst/proc
cd /DataVolume/debinst
tar -cvzf ../shares/Public/debinsts.tgz ./
```

На шаре Public будет лежать архив debinst.tgz — user-space образ готовой системы.

В случае нативной компиляции MBL можно не покидать и [собрать](http://code.google.com/p/mbl-common/wiki/PureDebianKernelSpace) на нём будущее ядро.

После сборки user-space и kernel-space частей остаётся [склеить](http://code.google.com/p/mbl-common/wiki/PureDebianPutTogether) их вместе для получения образа новой рабочей системы.