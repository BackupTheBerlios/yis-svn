#!/bin/bash

exec >/dev/console 2>&1 </dev/console

#This script is GPL and part of the yoper-commandline-installer

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n" 1>&2
	exit 1
fi

abort_on_error(){

echo " " 1>&2
echo " " 1>&2
[ -n "$1" ] && echo "$(color ltgreen black)The bootloader installation failed : "$1" !" 1>&2
[ -z "$1" ] && echo "$(color ltgreen black)The bootloader installation failed for an unknown reason. " 1>&2
echo "" 1>&2
echo "$(color ltgreen black)When you want to try again enter $(color ltred black)setup " 1>&2
echo "" 1>&2
color off
set +x
umount ${INST_ROOT}/proc
RETVAL=1
exit 1

}

[ -f /proc/version ] || mount -t proc proc /proc 2>/dev/null
[ -d /sys/devices ] || mount -t sysfs sysfs /sys 2>/dev/null
[ -f ${INST_ROOT}/proc/version ] || mount -t proc proc ${INST_ROOT}/proc 2>/dev/null

cp -a /dev/[h,s]d* $INST_ROOT/dev || abort_on_error "Could not copy device nodes"
root_dev="`cat $TMP/root_partition_choice`" || abort_on_error "No root partition defined"
[ -n "$root_dev" ] && BOOT_DEV="`echo $root_dev | cut -c1-8`"

if [ "$UID" == "0" ] && [ -n "$BOOT_DEV" ] ; then

	[ -z "`cat $INST_ROOT/etc/lilo.conf`" ] && \
	abort_on_error "$(color ltred black)no valid boot menu !" 
			
	sleep 0.2
	/sbin/lilo -M "${BOOT_DEV}" -b "${BOOT_DEV}" -r $INST_ROOT > /dev/null 2>&1 || abort_on_error "Step 1"
	/sbin/lilo -r $INST_ROOT > /dev/null 2>&1 || abort_on_error "Step 2"
	sleep 0.2
else
	abort_on_error "Why aren't you root ?" 
fi

sleep 0.5

rm -f $INST_ROOT/dev/[h,s]d*
umount ${INST_ROOT}/proc

exec >/dev/console 2>&1 </dev/console

