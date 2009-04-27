#!/bin/bash

RETVAL=0

source /etc/yis/settings || RETVAL=1 exit 1

/bin/mount -nt proc proc ${INST_ROOT}/proc 2>/dev/null || :
/bin/mount -nt sysfs sysfs ${INST_ROOT}/sys 2>/dev/null || :

INST_ROOT_DEV="`cat /ramdisk/YIS/settings/etc/fstab |grep "#yoper-root" | awk '{print $1}' 2>/dev/null`"

cp -a /dev/console $INST_ROOT_DEV "${INST_ROOT}/dev"

echo "#!/bin/bash" > ${INST_ROOT}/tmp/mkinitrd
echo "/usr/sbin/yaird -o /boot/initrd.img-$KVERSION $KVERSION " >> ${INST_ROOT}/tmp/mkinitrd
chmod +x ${INST_ROOT}/tmp/mkinitrd 

wait

chroot ${INST_ROOT} /tmp/mkinitrd || RETVAL=1
sleep 0.2

