#! /bin/bash

# Author: Tobias Gerschner
# Last modified : 29 / November / 2006
# Homepage: http://sourceforge.net/projects/yis 
# Some ideas are lent on the kanotix / knoppix - autoconfig script
#
# This script is under GPL License

# Some parts of it are taken out of the kanotix / knoppix - autoconfig script

# Add GPL License

# Script purpose : Gather information about all block devices
# 
# Filter for existing linux partitions
# Provide media information for further processing in installation scripts

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	echo "no config file found"
	exit 1
fi

[ -z "`which parted 2>/dev/null`" ] && exit 1
[ -z "`which fdisk 2>/dev/null`" ] && exit 1

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

cat $DEVICEMAP > $output

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

fdisk -l | grep ^\/dev | awk '{print $1}' |sort -u > $DISKS

for line in `awk '{print $1}' $disks_choice` ; do
	echo "/dev/$line" > $output
done

}

read_linux_partitions(){

rm -f $LINUX_PARTITIONS

#echo "device fs size used" > $LINUX_PARTITIONS

cd $mntdir

for part in `fdisk -l | grep ^\/dev | grep Linux | awk '{print $1}' \
&& fdisk -l | grep ^\/dev | grep "Linux swap" | awk '{print $1}'` ; do

	if [ ! -z "$part" ] ; then

	part_dev=`echo $part | cut -c6-8`
	#echo part_dev $part_dev
	part_mnt=`echo $part | cut -c6-9`
	#echo part_mnt $part_mnt
	#echo "Searching what $part holds ... "
	part_no=`echo $part | cut -c9-10`

	if [ ! -z "`grep ^\${part} /etc/fstab |grep swap`" ] ; then
		startmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $2}'`"
		endmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $3}'`"
		size="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $4}'`"
		[ -z "`grep ^$part $LINUX_PARTITIONS 2>/dev/null`" ] && echo "$part swap $size $size $startmb $endmb" >> $LINUX_PARTITIONS
		continue
	fi

	mkdir -p $mntdir/$part_mnt
	mount $part $mntdir/$part_mnt -o ro > /dev/null 2>&1 &

	sleep 0.5

	part_fs=`grep -m 1 $part /proc/mounts | grep -i "ext2\|ext3\|ext4\|reiserfs\|reiser4\|xfs" | awk '{print $3}'`
	# Check for supported linux file systems
	
	if [ -n "$part_fs" ] ; then
		if [ -n "`cat /sys/block/$part_dev/$part_mnt/size`" ] ; then
			sizemb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $4}'`"
			startmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $2}'`"
			endmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $3}'`"
			 usedmb=$[`df | grep -m 1 $part | awk '{print $3 }'`/1024]
			[ -z "`grep ^$part $LINUX_PARTITIONS`" ] && \
			echo "$part $part_fs $sizemb $usedmb $startmb $endmb" >> $LINUX_PARTITIONS
			( umount $mntdir/$part_mnt -l > /dev/null 2>&1 &)
		fi
	fi

	sleep 0.1
	fi
done

mount /home > /dev/null 2>&1

cat $LINUX_PARTITIONS > $output
}

read_all_partitions(){

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

rm -f $ALL_PARTITIONS

#echo "device fs size used" > $ALL_PARTITIONS

cd $mntdir

kernel_fs=`grep -v ^nodev /proc/filesystems | xargs | sed 's# #\\\|#g' |sed 's#$#\\\|swap#'`

for part in `fdisk -l | grep ^\/dev | awk '{print $1}'` ; do

	if [ ! -z "$part" ] ; then

	part_dev=`echo $part | cut -c6-8`
	#echo part_dev $part_dev
	part_mnt=`echo $part | cut -c6-9`
	#echo part_mnt $part_mnt
	#echo "Looking at $part ... "

	part_no=`echo $part | cut -c9-10`
	
	if [ ! -z "`grep ^\${part} /etc/fstab |grep swap`" ] ; then
		startmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $2}'`"
		endmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $3}'`"
		size="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $4}'`"
		[ -z "`grep ^$part $ALL_PARTITIONS 2>/dev/null`" ] && echo "$part swap $size $size $startmb $endmb" >> $ALL_PARTITIONS
		continue
	fi

	mkdir -p $mntdir/$part_mnt
	mount $part $mntdir/$part_mnt -o ro > /dev/null 2>&1 &
	sleep 1

# Check for all kernel supported file systems
	part_fs=`grep -m 1 $part /proc/mounts | grep "$kernel_fs" | awk '{print $3}'`

#	part_fs=`cat /proc/mounts | grep -m 1 $part | awk '{print $3}' `

	if [ -n "$part_fs" ] ; then
		if [ -n "`cat /sys/block/$part_dev/$part_mnt/size`" ] ; then
			sizemb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $4}'`"
			startmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $2}'`"
			endmb="`/usr/sbin/parted -s /dev/${part_dev} unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$part_no | awk '{print $3}'`"
			 usedmb=$[`df | grep -m 1 $part | awk '{print $3 }'`/1024]
			[ -z "`grep ^$part $ALL_PARTITIONS`" ] && \
			echo "$part $part_fs $sizemb $usedmb $startmb $endmb" >> $ALL_PARTITIONS
			( umount $mntdir/$part_mnt -l > /dev/null 2>&1 &)
		fi
	fi

	sleep 0.2
	fi
done

cat $ALL_PARTITIONS > $output

}

#make sure we do not quit on error
#needed for sane error handling
set +e

output=$2
pwd=`pwd`
if [ -n "$output" ] ; then
	[ "`echo $output | awk -F '/' '{print $1}'`" == "$output" ] && output=${pwd}/$output
else
	output=/dev/null
fi

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

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
		echo "Usage for $0 : exec option outputfile"
		echo ''
		echo ' read_all_partitions 	# create list of all existing Partitions recognized by the kernel into $2 '
		echo ' read_linux_partitions 	# create list of all existing Linux Partitions into $2 '
		echo ' list_hdds 		# create list of all existing non removable mass storages into $2 '
		echo ' generate_device_map	# create grub device map in $2 '
		echo ''
		echo ' $2 should preferably give the full path '
		echo ' You can also use /dev/stdout to tell it to output the results'
		
		exit 1
		;;
esac

cd $pwd
