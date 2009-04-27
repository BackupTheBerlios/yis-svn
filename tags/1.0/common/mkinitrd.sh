#!/bin/bash

source /var/yis/settings

/bin/mount -nt proc proc /ramdisk/YIS/root/proc 2>/dev/null || :
/bin/mount -nt sysfs sysfs /ramdisk/YIS/root/sys 2>/dev/null || :

INST_ROOT=`cat /ramdisk/YIS/settings/etc/fstab | grep "#yoper-root" | awk '{print $1}'`
(
cp -a $INST_ROOT "/ramdisk/YIS/root$INST_ROOT"
cp -a /dev/console /ramdisk/YIS/root/dev
echo "#!/bin/bash" > /ramdisk/YIS/root/tmp/mkinitrd
echo "/usr/sbin/yaird -o /boot/initrd.img-$KVERSION $KVERSION " >> /ramdisk/YIS/root/tmp/mkinitrd
chmod +x /ramdisk/YIS/root/tmp/mkinitrd )
wait

chroot /ramdisk/YIS/root /tmp/mkinitrd || RETVAL=1
sleep 1

