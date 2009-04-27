#!/bin/bash

exec >/dev/console 2>&1 </dev/console

#This script is GPL and part of the yoper-commandline-installer

if [ -f /var/yis/settings ] ; then
	source /var/yis/settings
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

RETVAL=1
exit 1

}

if [ ! -z "`cat $HDSTORE 2>/dev/null`" ] ; then

	[ -f /proc/version ] || mount -t proc proc /proc 2>/dev/null
	[ -d /sys/devices ] || mount -t sysfs sysfs /sys 2>/dev/null

	cp -a /dev/hd* $INST_ROOT/dev || abort_on_error
	cp -a /dev/sd* $INST_ROOT/dev 2>/dev/null

	sleep 1

	cp -a $HDSTORE $BOOT_DEV	

	root_dev="/dev/`cat $TMP/root_partition_choice`" || abort_on_error

	if [ "$UID" == "0" ] ; then

		cat /var/yis/common/lilo.conf.template | \

		# add path where lilo gets installed
		sed "s:BOOT_DEV:"`cat $BOOT_DEV`":g" | \

		# Change Yoper Version
		sed "s:YVERSION:"$YVERSION":g" | \

		# Change root partition in boot cmdline
		sed "s:ROOT_DEV:$root_dev:g" | \
	
		# Change Kernel Version
		sed "s:KVERSION:"$KVERSION":g" > $INST_ROOT/etc/lilo.conf

		[ -z "`cat $INST_ROOT/etc/lilo.conf`" ] && \
		abort_on_error "$(color ltred black)no valid boot menu !" 
			
		sleep 0.2
		/sbin/lilo -M "/dev/`cat $BOOT_DEV`" -r $INST_ROOT > /dev/null || abort_on_error
		/sbin/lilo -r $INST_ROOT > /dev/null || abort_on_error
		sleep 0.2
	else
		abort_on_error "Why aren't you root ?" 
	fi
else
		echo "Skipping bootloader ..."
fi

sleep 0.5

rm -f $INST_ROOT/dev/hd*
rm -f $INST_ROOT/dev/sd*

exec >/dev/console 2>&1 </dev/console

