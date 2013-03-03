#!/bin/sh

SCRIPT_NAME='wedro_chroot.sh'
SCRIPT_START='99'
SCRIPT_STOP='01'

MOUNT_DIR='/DataVolume/shares'

CHROOT_DIR="__CHROOT_DIR_PLACEHOLDER__"
CHROOT_SERVICES="$(cat __CHROOT_DIR_PLACEHOLDER/chroot-services.list)"

### BEGIN INIT INFO
# Provides:          $SCRIPT_NAME
# Required-Start:    wedro_mount.sh
# Required-Stop:
# X-Start-Before:
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
### END INIT INFO

script_install() {
  cp $0 /etc/init.d/$SCRIPT_NAME
  chmod a+x /etc/init.d/$SCRIPT_NAME
  update-rc.d $SCRIPT_NAME defaults $SCRIPT_START $SCRIPT_STOP > /dev/null
}

script_remove() {
  update-rc.d -f $SCRIPT_NAME remove > /dev/null
  rm -f /etc/init.d/$SCRIPT_NAME
}

#######################################################################

MOUNT_COUNTS="$(mount | grep $CHROOT_DIR | wc -l)"

check_mounted() {
  if [[ $MOUNT_COUNTS -lt 1 ]]; then
      echo "CHROOT sems unmounted. exiting"
      exit 1
  fi
}

CHROOT_COUNTS="$(chroot $CHROOT_DIR mount | wc -l)"

check_started() {
  check_mounted
  if [[ $CHROOT_COUNTS -gt 0 ]]; then
      echo "CHROOT sems started. exiting"
      exit 1
  fi
}

check_stopped() {
  check_mounted
  if [[ $CHROOT_COUNTS -eq 0 ]]; then
      echo "CHROOT sems stopped. exiting"
      exit 1
  fi
}

#######################################################################

start() {
#    check_started

    mount --bind $MOUNT_DIR $CHROOT_DIR/mnt

    chroot $CHROOT_DIR mount -t proc none /proc -o rw,noexec,nosuid,nodev
    chroot $CHROOT_DIR mount -t sysfs none /sys -o rw,noexec,nosuid,nodev
    chroot $CHROOT_DIR mount -t devpts none /dev/pts -o rw,noexec,nosuid,gid=5,mode=620

    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM start
    done
}

stop() {
#    check_stopped

    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM stop
    done

    chroot $CHROOT_DIR umount /dev/pts
    chroot $CHROOT_DIR umount /sys
    chroot $CHROOT_DIR umount /proc

    umount $CHROOT_DIR/mnt
}

#######################################################################

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1
        start
    ;;
    install)
        script_install
    ;;
    init)
        script_install
        sleep 1
        start
    ;;
    remove)
        stop
        sleep 1
        script_remove
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart|update|upgrade|upgrade-system}"
        exit 1
esac

exit $?
