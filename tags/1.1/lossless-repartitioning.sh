#! /bin/bash

# Author: Tobias Gerschner
# Last modified : 05 / August / 2006
# Homepage: http://sourceforge.net/projects/yis 
# Some ideas are lent on the kanotix / knoppix - autoconfig script
#
# This script is under GPL License

# Some parts of it are taken out of the kanotix / knoppix - autoconfig script

# Add GPL License

# Script purpose : Gather information about all block devices
# 
# Filter for existing linux partitions
#

# We need system information about the partitions and need therefore ensure it's there

# This file shall hold all verified linux partitions + additional information

source /etc/yis/settings

[ -f /proc/version ] || mount -t proc proc /proc 2>/dev/null
[ -d /sys/devices ] || mount -t sysfs sysfs /sys 2>/dev/null

mntdir=$TMP/partitions

mkdir -p $mntdir

for rem in `ls -1d $mntdir/* > /dev/null 2>&1` ; do 
	umount -l $rem > /dev/null 2>&1 &
done

generate_device_map(){

# generate grub device map

rm -f $DEVICEMAP
echo "(fd0) /dev/fd0" > $DEVICEMAP

line=0
for check in `fdisk -l | grep ^\/dev | cut -c1-8 |sort -u` ; do
	echo "(hd${line}) $check" >> $DEVICEMAP
	line=$[line+1]
done

}

# Gather media info

list_hdds(){

rm -f  $disks_choice $DISKS

NUMHD=0

# ensure we don't list unsuitable devices

for dev in `fdisk -l | grep ^\/dev | cut -c6-8 |sort -u` ; do


[ -e "/proc/ide/$dev/media" ] &&  	if [ "`cat /proc/ide/$dev/media`" = "disk" ] ; then
					echo "$dev `tr ' ' _ </proc/ide/$dev/model`" >> $disks_choice
					NUMHD=$[NUMHD+1]
	        			fi && continue

[ -e "/sys/block/$dev/removable" ] && 	if [ "`cat /sys/block/$dev/removable`" = "0" ] ; then
					echo "$dev `tr ' ' _ </sys/block/$dev/device/model`" >> $disks_choice
					NUMHD=$[NUMHD+1]
        				fi
done

export NUMHD

for dev in `fdisk -l | grep ^\/dev | awk '{print $1}' |sort -u` ; do
	echo $dev >> $DISKS
done

}

read_linux_partitions(){

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

rm -f $LINUX_PARTITIONS

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

echo "device fs size used" > $LINUX_PARTITIONS

cd $mntdir

for part in `fdisk -l | grep ^\/dev | grep Linux | awk '{print $1}' \
&& fdisk -l | grep ^\/dev | grep "Linux swap" | awk '{print $1}'` ; do

	if [ ! -z "$part" ] ; then

	part_dev=`echo $part | cut -c6-8`
	#echo part_dev $part_dev
	part_mnt=`echo $part | cut -c6-9`
	#echo part_mnt $part_mnt
	echo "Searching what $part holds ... "
	
	if [ ! -z "`grep ^\$part /etc/fstab |grep swap`" ] ; then
		size=$[`disktype $part | grep "^Block device" | awk '{print $6}' |sed 's/^(//1'`/1024]
		[ -z "`grep ^$part $LINUX_PARTITIONS`" ] && echo "$part swap $size $size" >> $LINUX_PARTITIONS
		continue
	fi

	mkdir -p $mntdir/$part_mnt
	mount $part $mntdir/$part_mnt -o ro > /dev/null 2>&1 || continue

	# Check for supported linux file systems
	for fs in ext2 ext3 xfs reiserfs reiser4 ; do

	part_fs=`cat /proc/mounts | grep -m 1 $part | awk '{print $3}' `

	if [ "$part_fs" == "$fs" ] ; then
		if [ ! -z "`cat /sys/block/$part_dev/$part_mnt/size`" ] ; then
			[ -z "`grep ^$part $LINUX_PARTITIONS`" ] && \
			echo -ne "$part $part_fs `df | grep -m 1 $part | awk '{print $2,$3 }'`\n" >> $LINUX_PARTITIONS
			( umount $mntdir/$part_mnt -l > /dev/null 2>&1 )
			wait
		fi
	fi
	done
	sleep 0.1
	fi
done

mount /home > /dev/null 2>&1

}

read_all_partitions(){

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

rm -f $ALL_PARTITIONS

echo "device fs size used" > $ALL_PARTITIONS

cd $mntdir

for part in `fdisk -l | grep ^\/dev | awk '{print $1}'` ; do

	if [ ! -z "$part" ] ; then

	part_dev=`echo $part | cut -c6-8`
	#echo part_dev $part_dev
	part_mnt=`echo $part | cut -c6-9`
	#echo part_mnt $part_mnt
	echo "Searching what $part holds ... "
	
	if [ ! -z "`grep ^\${part} /etc/fstab |grep swap`" ] ; then
		size=$[`disktype $part | grep "^Block device" | awk '{print $6}' |sed 's/^(//1'`/1024]
		#size=`disktype ${part} | grep "^Block device" | awk '{print $6}' |sed 's/^(//1'`
		[ -z "`grep ^$part $ALL_PARTITIONS`" ] && echo "$part swap $size $size" >> $ALL_PARTITIONS
		#echo "$part swap $size $size" >> $LINUX_PARTITIONS
		continue
	fi

	mkdir -p $mntdir/$part_mnt
	mount $part $mntdir/$part_mnt -o ro > /dev/null 2>&1 || continue

	# Check for all supported file systems
	for fs in `grep -v ^nodev /proc/filesystems` ; do

	part_fs=`cat /proc/mounts | grep -m 1 $part | awk '{print $3}' `

	if [ "$part_fs" == "$fs" ] ; then
		if [ ! -z "`cat /sys/block/$part_dev/$part_mnt/size`" ] ; then
			[ -z "`grep ^$part $ALL_PARTITIONS`" ] && \
			echo -ne "$part $part_fs `df | grep -m 1 $part | awk '{print $2,$3 }'`\n" >> $ALL_PARTITIONS
			#echo -n "$part $part_fs " >> $ALL_PARTITIONS ;
			#echo -n `df | grep -m 1 $part | awk '{print $2,$3 }'` >> $ALL_PARTITIONS
			#echo " " >> $ALL_PARTITIONS
			( umount $mntdir/$part_mnt -l > /dev/null 2>&1 )
			wait
		fi
	fi
	done
	sleep 0.2
	fi
done

mount /home > /dev/null 2>&1

}

set -e

case "$1" in
	read_linux_partitions) 
		read_linux_partitions
		;;
	list_hdds)
		list_hdds
		;;
	generate_device_map)
		generate_device_map
		;;
	read_all_partitions)
		read_all_partitions
		;;
	source)
		exit 0
		;;
	*)
		exit 1
		;;
esac

set +e
