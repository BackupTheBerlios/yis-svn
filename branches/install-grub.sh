#!/bin/bash


#This script is GPL and part of the yoper-commandline-installer

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n" 1>&2
	exit 1
fi

[ -f /proc/version ] || mount -t proc proc /proc 2>/dev/null
[ -d /sys/devices ] || mount -t sysfs sysfs /sys 2>/dev/null

root_dev="`cat $TMP/root_partition_choice 2>/dev/null`"
FS=$(cat $TMP/fs_choice 2>/dev/null)

rm -f /tmp/.grubfail

func_install_lilo(){

	pid="`/sbin/pidof /sbin/grub `"
	for p in $pid ; do kill -9 $p >/dev/null 2>&1 ; done

	mount $root_dev $INST_ROOT >/dev/null 2>&1 

	clear
	echo "Grub failed, switching to lilo ..."
	rm -f $run
	echo lilo > $INST_ROOT/etc/sysconfig/bootloader
	$TOP_DIR/common/install-lilo.sh
	sleep 1

}

func_install_grub() {

umount $INST_ROOT/proc
umount $INST_ROOT/sys

sync

umount $INST_ROOT -l
sleep 1 

run=`mktemp`

echo "#!/bin/bash
mount $root_dev $INST_ROOT >/dev/null 2>&1
sync 
" > $run

if test "$FS" = "xfs" ; then
echo "
xfs_freeze -f $INST_ROOT 2>/dev/null 
sleep 1 
" >> $run
fi

echo "
/sbin/grub --batch --config-file=/boot/grub/grub.conf < /etc/grub-install.conf || touch /tmp/.grubfail

" >> $run

if test "$FS" = "xfs" ; then

echo "
sleep 1
xfs_freeze -u $INST_ROOT 2>/dev/null
" >> $run

fi

chmod +x $run
( sh -i -x $run & )

}

if [ "$UID" = "0" -a -n "`cat $INST_ROOT/boot/grub/grub.conf 2>/dev/null`" -a -d /usr/share/grub/i386-pc ] ; then
	cp -a -f /dev/[h,s]d* $INST_ROOT/dev || func_install_lilo
	mkdir -p $INST_ROOT/boot/grub /tmp2
	cp -a -f /usr/share/grub/i386-pc/* $INST_ROOT/boot/grub || func_install_lilo
	cp -a -f $INST_ROOT/boot/grub/device.map /tmp2 || func_install_lilo
	cp -a -f $INST_ROOT/boot/grub/grub.conf /tmp2 || func_install_lilo

	func_install_grub 
	count=0
	while [ -n "`/sbin/pidof $run`" ] ; do
		sleep 0.5
		count=$[count+1]
		[ "$count" -gt "20" ] && break
	done

	test "$FS" = "xfs" && xfs_freeze -u $INST_ROOT

else
	func_install_lilo
fi

[ -d "${INST_ROOT}/dev" ] && rm -f $INST_ROOT/dev/[h,s]d*

[ -n "`/sbin/pidof /sbin/grub`" ] && func_install_lilo
[ -f /tmp/.grubfail ] && func_install_lilo

exit 0

