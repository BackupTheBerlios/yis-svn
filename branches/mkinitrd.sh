#!/bin/bash

RETVAL=0

source /etc/yis/settings || RETVAL=1 exit 1

/bin/mount -nt proc proc ${INST_ROOT}/proc 2>/dev/null || :
/bin/mount -nt sysfs sysfs ${INST_ROOT}/sys 2>/dev/null || :

INST_ROOT_DEV="`grep "#yoper-root" /ramdisk/YIS/settings/etc/fstab | awk '{print $1}' 2>/dev/null`"

oldfstab=$(mktemp)
cp -a /etc/fstab $oldfstab
cp -a /ramdisk/YIS/settings/etc/fstab /etc/fstab

/usr/sbin/yaird -o ${INST_ROOT}/boot/initrd.img-$KVERSION $KVERSION || RETVAL=1

sleep 1

mv $oldfstab /etc/fstab
