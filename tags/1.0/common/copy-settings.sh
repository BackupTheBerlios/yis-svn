#! /bin/bash

# This script copies the finished settings collected through YIS into the mounted root partition

source /var/yis/settings

for FILE in `find /ramdisk/YIS/settings` ; do
	DEST=`echo $FILE | sed 's:/ramdisk/YIS/settings::1'`
	cp -a $FILE /ramdisk/YIS/root/$DEST || RETVAL=1
done

# Now remove old settings from Install CD
rm -fr /ramdisk/YIS/root/yis
rm -fr /ramdisk/YIS/root/settings
rm -f /ramdisk/YIS/root/usr/bin/setup
rm -f /ramdisk/YIS/root/etc/rc.d/rc5.d/S99yoper
rm -f /ramdisk/YIS/root/etc/rc.d/rcS.d/S00*

# Fix initfiles
[ -a /KNOPPIX/yis/common/fix-init.tar.bz2 ] && tar xf /KNOPPIX/yis/common/fix-init.tar.bz2 -C /ramdisk/YIS/root/
sleep 0.5


