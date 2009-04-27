#! /bin/bash

# This document is originally written by Tobias Gerschner as part of the yis project
# http://sourceforge.net/projects/yis 

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

mkdir -p $TMP_DIR/partitions

for rem in `ls -1d $TMP_DIR/partitions/* > /dev/null 2>&1` ; do 
	umount -l $rem > /dev/null 2>&1 &
done

# Collect partitions from /proc/partitions

partitions=""
while read major minor blocks partition relax; do
        partition="${partition##*/}"
        [ -z "$partition" -o ! -e "/dev/$partition" ] && continue
        case "$partition" in
                hd?) ;;                                               # IDE Harddisk, entire disk
                sd?) ;;                                               # SCSI Harddisk, entire disk
                [hs]d*) partitions="$partitions /dev/$partition"    # IDE or SCSI disk partition
		;;
        esac
	# echo $partition 
done <<EOF
$(awk 'BEGIN{old="__start"}{if($0==old){exit}else{old=$0;if($4&&$4!="name"){print $0}}}' /proc/partitions) 
EOF

# Write all partitions

rm -f $DISKS && touch $DISKS
for part in `echo $partitions` ; do echo $part >> $DISKS ; done

# Filter disks

rm -f $disks_choice && touch $disks_choice
cat $DISKS | cut -c1-8 | sort -u > $DEV_DISKS

# generate grub device map

rm -f $DEVICEMAP
touch $DEVICEMAP || exit 1
echo "(fd0) /dev/fd0" > $DEVICEMAP

line=0
for check in `cat $DEV_DISKS` ; do
	echo "(hd${line})   $check" >> $DEVICEMAP
	line=$[line+1]
done

# Gather media info

NUMHD=0

for dev in `cat $DEV_DISKS | cut -c6-8` ; do


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
# This file shall hold all verified linux partitions

[ "$UID" != "0" ] && echo "You're not root and cannot mount partitions, stoping here ... " && exit 1

rm -f $LINUX_PARTITIONS

echo "device fs size used" > $LINUX_PARTITIONS

mkdir -p $TMP_DIR/partitions
cd $TMP_DIR/partitions

for part in `echo $partitions` ; do

	if [ ! -z "$part" ] ; then

	part_dev=`echo $part | cut -c6-8`
	#echo part_dev $part_dev
	part_mnt=`echo $part | cut -c6-9`
	#echo part_mnt $part_mnt
	echo "Searching what $part holds ... "
	mkdir -p $TMP_DIR/partitions/$part_mnt
	mount $part $TMP_DIR/partitions/$part_mnt -o ro > /dev/null 2>&1 &
	
	# Check for supported linux file systems
	for fs in ext2 ext3 xfs reiserfs reiser4 ; do

	part_fs=`cat /proc/mounts | grep -m 1 $part | awk '{print $3}' `

	if [ "$part_fs" == "$fs" ] ; then
		if [ ! -z "`cat /sys/block/$part_dev/$part_mnt/size`" ] ; then
			echo -n "$part $part_fs " >> $LINUX_PARTITIONS ;
			echo -n `df | grep -m 1 $part | awk '{print $2,$3 }'` >> $LINUX_PARTITIONS
			echo " " >> $LINUX_PARTITIONS
			( umount $part -l > /dev/null 2>&1 )
			wait
		fi
	fi
	done
	sleep 1
	fi
done

#mount /home > /dev/null 2>&1
exit 0
