#!/bin/sh

BOLD="\033[1;33m"
NORM="\033[0m"
INFO="$BOLD Info:$NORM"
ERROR="$BOLD Error:$NORM"
WARNING="$BOLD Warning:$NORM"
INPUT="$BOLD => $NORM"
if [ -z $1 ]
then
	chrootDir=debian
else
	chrootDir=$1
fi
chrootBaseDir=/DataVolume/$chrootDir
debootstrapPkgName=debootstrap_1.0.10lenny1_all.deb
projectURL=http://mbl-common.googlecode.com/svn/chroot-install
isServicesInstalled=no
wget -q -O - http://mbl-common.googlecode.com/files/downloadcounter.txt > /dev/null 2>&1
echo -e $INFO This script will guide you through the chroot-based services
echo -e $INFO installation on Western Digital My Book Live \(Duo\) NAS.
echo -e $INFO The goal is to install Debian Testing environment with no interference
echo -e $INFO with firmware. You will be asked later about which services to install
echo -en $INPUT Do you wish to continue [y/n]?
read userAnswer
if [ "$userAnswer" != "y" ]
then
	echo -e $INFO Ok then. Exiting.
	exit 0
fi

if [ -e /etc/init.d/chroot_$chroot.sh ]
then
	echo -e $ERROR Chroot\'ed services start/stop script detected! Please, remove
	echo -e $ERROR previous installation or specify destination folder name
	echo -e $ERROR and run script again with <foldername> parameter, for example:
	echo -e $ERROR ./install.sh my_debian
	exit 1
fi
if [ -d $chrootBaseDir ]
then
	echo -e $WARNING Previous chroot environment will be moved to $chrootBaseDir.old
	[ -d $chrootBaseDir.old ] || mkdir $chrootBaseDir.old
	mv -f $chrootBaseDir/* $chrootBaseDir.old
else
	mkdir $chrootBaseDir
fi
echo -e $INFO Deploying a debootstrap package...
wget -q -O /tmp/$debootstrapPkgName $projectURL/$debootstrapPkgName
dpkg -i /tmp/$debootstrapPkgName > /dev/null 2>&1
rm -f /tmp/$debootstrapPkgName
ln -sf /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/testing
echo -e $INFO Preparing a new Debian Testing chroot file base. Please, be patient,
echo -e $INFO may takes a long time on low speed connection...
debootstrap --variant=minbase --exclude=yaboot,udev,dbus --include=mc,aptitude testing $chrootBaseDir ftp://ftp.debian.org/debian
chroot $chrootBaseDir apt-get update > /dev/null 2>&1
echo -e $INFO A Debian Testing chroot environment  installed.
echo -e $INFO Now deploying services start script...
wget -q -O $chrootBaseDir/chroot_$chrootDir.sh $projectURL/wedro_chroot.sh
eval sed -i 's,__CHROOT_DIR_PLACEHOLDER__,$chrootBaseDir,g' $chrootBaseDir/chroot_$chrootDir.sh
chmod +x $chrootBaseDir/chroot_$chrootDir.sh
touch $chrootBaseDir/chroot-services.list
$chrootBaseDir/chroot_$chrootDir.sh install
echo >> $chrootBaseDir/root/.bashrc
echo PS1=\'\(chroot-$chrootDir\)\\w\# \' >> $chrootBaseDir/root/.bashrc
echo -e $INFO ...finished.

echo -en $INPUT Do you wish to install miniDLNA UPnP/DLNA server [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	isServicesInstalled=yes
	echo -e $INFO UPnP/DLNA content will be taken from \"Public/Shared Music\",
	echo -e $INFO \"Public/Shared Pictures\" and\"Public/Shared Videos\" shares.
	chroot $chrootBaseDir apt-get --force-yes -qqy install minidlna
	chroot $chrootBaseDir /etc/init.d/minidlna stop > /dev/null 2>&1
	chroot $chrootBaseDir /etc/init.d/minissdpd stop > /dev/null 2>&1
	killall minidlna > /dev/null 2>&1
	[ -d "/DataVolume/shares/Public/Shared Music" ] || mkdir "/DataVolume/shares/Public/Shared Music"
	[ -d "/DataVolume/shares/Public/Shared Pictures" ] || mkdir "/DataVolume/shares/Public/Shared Pictures"
	[ -d "/DataVolume/shares/Public/Shared Videos" ] || mkdir "/DataVolume/shares/Public/Shared Videos"
	sed -i 's|^media_dir=/var/lib/minidlna|media_dir=A,/mnt/Public/Shared Music\nmedia_dir=P,/mnt/Public/Shared Pictures\nmedia_dir=V,/mnt/Public/Shared Videos|g' $chrootBaseDir/etc/minidlna.conf
	rm -f $chrootBaseDir/var/lib/minidlna/files.db
	echo minidlna >> $chrootBaseDir/chroot-services.list
	echo -e $INFO MiniDLNA is installed.
fi

echo -en $INPUT Do you wish to install Transmission BitTorrent client [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	isServicesInstalled=yes
	[ -d /DataVolume/shares/Public/Torrents ] || mkdir /DataVolume/shares/Public/Torrents
	echo -e $INFO Torrents content will be downloaded to \"Public/Torrents\" share. Installing...
	chroot $chrootBaseDir apt-get --force-yes -qqy install transmission-daemon
	chroot $chrootBaseDir /etc/init.d/transmission-daemon stop > /dev/null 2>&1
	wget -q -O $chrootBaseDir/etc/transmission-daemon/settings.json $projectURL/settings.json
	chmod +rw $chrootBaseDir/etc/transmission-daemon/settings.json
	echo transmission-daemon >> $chrootBaseDir/chroot-services.list
	echo -e $INFO Transmission is installed.
fi

if [ "$isServicesInstalled" == "yes" ]
then
	echo -en $INPUT Do you wish to start chroot\'ed services right now [y/n]?
	read userAnswer
	if [ "$userAnswer" == "y" ]
	then
		/etc/init.d/chroot_$chrootDir.sh start
	fi
fi
echo -e $INFO Congratulation! Installation finished. You\'ve got a working
echo -e $INFO Debian Testing environment onboard.  You may install any services
echo -e $INFO you wish, but don\'t forget to add it\'s names to
echo -e $INFO $chrootBaseDir/chroot-services.list
echo -e $INFO /etc/init.d/chroot_$chrootDir.sh script is used
echo -e $INFO to start or stop chroot\'ed services.
echo -e $INFO Found bug? Please, report us!
echo -e $INFO http://code.google.com/p/mbl-common/issues/list