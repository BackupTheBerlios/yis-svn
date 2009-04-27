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
umount ${INST_ROOT}/proc 2>/dev/null
umount ${INST_ROOT}/sys 2>/dev/null
RETVAL=1
killall cli.sh
killall bash
exit 1

}

#ugly and same in write-bootloader-config.sh

convert_alpha_num(){

[ -z "$1" ] && abort_on_error

[ "$1" == "a" ] && root_num=0
[ "$1" == "b" ] && root_num=1
[ "$1" == "c" ] && root_num=2
[ "$1" == "d" ] && root_num=3
[ "$1" == "e" ] && root_num=4
[ "$1" == "f" ] && root_num=5
[ "$1" == "g" ] && root_num=6
[ "$1" == "h" ] && root_num=7

}


func_run_grub() {

run=`mktemp`

echo "#!/bin/sh
sleep 2
/sbin/grub --config-file=$INST_ROOT/boot/grub/grub.conf --device-map=/tmp/yis/device.map --batch <<EOT 1>/dev/null 2>/dev/null
root (${root_hd},${root_part})
setup (hd0)
quit

EOT
#setup (${root_hd})

" > ${run}

chmod +x $run
( $run && rm -f $lock $run )

}

[ -f /proc/version ] || mount -t proc proc /proc 2>/dev/null
[ -d /sys/devices ] || mount -t sysfs sysfs /sys 2>/dev/null
[ -f ${INST_ROOT}/proc/version ] || mount -t proc proc ${INST_ROOT}/proc 2>/dev/null

cp -a /dev/[h,s]d* $INST_ROOT/dev || abort_on_error
mkdir -p $INST_ROOT/boot/grub
cp -a $DEVICEMAP $INST_ROOT/boot/grub/device.map

root_dev="`cat $TMP/root_partition_choice`"
boot_dev="`echo $root_dev | cut -c1-8`"

root_num="`echo $root_dev | cut -c8-8`"
convert_alpha_num $root_num
root_hd="`echo $root_dev | cut -c6-7`${root_num}"
root_part="`echo $root_dev | cut -c9-9`"
root_part=$[root_part-1]

[ "$root_part" -lt "0" ] && root_part=0

if [ "$UID" == "0" ] ; then
	
# make sure everything is written as supposed
if [ -d /usr/share/grub/i386-pc ] ; then
	mkdir -p $INST_ROOT/boot/grub
	cp -a /usr/share/grub/i386-pc/* $INST_ROOT/boot/grub
else
	abort_on_error "Grub stage files not found, grub not installed ?"
fi

[ -z "`cat $INST_ROOT/boot/grub/grub.conf`" ] && abort_on_error "$(color ltred black)no valid boot menu !" 
			
sleep 0.5

umount $INST_ROOT/proc
umount $INST_ROOT/sys

#mount $INST_ROOT -o remount,ro >/dev/null 2>&1 || abort_on_error "Could not mount the root partition read only"
umount $INST_ROOT

lock=`mktemp`

func_run_grub 
count=0


while [ -f "$lock" ] ; do

	sleep 1
	count=$[count+1]

	if [ "$count" >= "100" ] ; then
		pid="`ps axu |grep "\$run" | grep -v grep | awk '{print $2}'`"
		kill -9 $pid >/dev/null 2>&1
		killall grub >/dev/null 2>&1
		if [ -f "$lock" ] ; then
			rm -f $lock $run
			$TOP_DIR/common/install-lilo.sh
		fi
	fi
done

else
	abort_on_error "Only root can run this script." 
fi

sleep 0.5

mount $INST_ROOT >/dev/null 2>&1 

[ -d "${INST_ROOT}/dev" ] && rm -f $INST_ROOT/dev/[h,s]d*

exec >/dev/console 2>&1 </dev/console

