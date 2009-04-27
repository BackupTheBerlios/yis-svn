#!/bin/bash
# -e better break the script than the system, yet to be included

#This installer is GPL

( killall cp > /dev/null 2>&1 )

( umount -l /ramdisk/YIS/root/proc > /dev/null 2>&1
  umount -l /ramdisk/YIS/root/sys > /dev/null 2>&1
  umount -l /ramdisk/YIS/root > /dev/null 2>&1 )
wait

for dev in `cat /proc/partitions | awk '{print $4}' | grep [h,s]*[1-9]` ; do
	( umount -l /dev/$dev > /dev/null 2>&1 )
done

[ "$1" == "debug" ] && set -x 

#
# The script assumes the following
#
# - TOP_DIR one directory level above
# - settings stored in TOP_DIR
# - running common functions from $TOP_DIR/common
# 

if [ -f /var/yis/settings ] ; then
	source /var/yis/settings
else
	echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n"
	exit 1
fi

[ ! -d "$TOP_DIR" ] && echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n" && exit 1

cancel_install(){

( umount -l /ramdisk/YIS/root/proc > /dev/null 2>&1
  umount -l /ramdisk/YIS/root/sys > /dev/null 2>&1
  umount -l /ramdisk/YIS/root > /dev/null 2>&1 )
wait

echo " "
echo " "
echo " "
echo "$(color ltgreen black)You have chosen to cancel Yoper installation ... "
echo ""
echo "$(color ltgreen black)When you want to try again enter $(color ltred black)setup "
echo ""
color off
exit 1

}

abort_on_error(){

echo " "
echo " "
[ -n "$1" ] && echo "$(color ltgreen black)The installation failed : "$1" !"
[ -z "$1" ] && echo "$(color ltgreen black)The installation failed for an unknown reason. "
echo ""
echo "$(color ltgreen black)When you want to try again enter $(color ltred black)setup "
echo ""
color off

( umount -l /ramdisk/YIS/root/proc > /dev/null 2>&1
  umount -l /ramdisk/YIS/root/sys > /dev/null 2>&1
  umount -l /ramdisk/YIS/root > /dev/null 2>&1 )
wait

exit 1

}


$DIALOG --backtitle "YOUR Operating System Installation Program" --title "DISCLAIMER" --yesno "
\n \n By pressing YES you agree: \n \n
YOPER(TM) LIMITED AND YOPER(TM) HOLDINGS LIMITED DISCLAIM ALL WARRANTIES, EXPRESS OR
IMPLIED, WITH REGARD TO THIS SOFTWARE, INCLUDING WITHOUT LIMITATION
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, AND IN NO EVENT SHALL YOPER LIMITED AND YOPER HOLDINGS LIMITED BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, TORT (INCLUDING NEGLIGENCE) OR STRICT LIABILITY,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.                                                               \n
- The source code for some software on this CD is available via the appropriate maintainers website and also via  the apt update service.\n
- Yoper(TM) is distributed under the GPL (www.gnu.org).\n
- Yoper(TM) is a Trademark of Yoper(TM) Holdings Limited.\n
If you do not agree press the No button." 25 75

case $? in
  0)
echo ""
;;
  1)
cancel_install
;;
  255)
cancel_install
;;
esac


$DIALOG --backtitle "YOUR Operating System Installation Program"  --title "YOS Installation" \
        --yesno "Would you like to check the integrity of the installfiles? \
                This will allow you to ascertain if the iso you downloaded \
                is corrupt or not. \
                Do this only if you have issues installing, \
                since it will take time. " 15 61

case $? in
  0)
echo "Proceeding ... "
. $TOP_DIR/common/checkmd5sum.sh || abort_on_error "MD5Sum Check revealed corrupted media"
exec >/dev/console 2>&1 </dev/console

;;
  1)
sleep 0.2
;;
  255)
cancel_install
;;
esac


#
# This scripts gathers the harddisk and partition information and if run as root also the linux partitions
# 

run_cfdisk(){

source /var/yis/settings

. $TOP_DIR/common/detect-valid-partitions.sh > /dev/null # || abort_on_error "Cannot access your disk drives properly"
exec >/dev/console 2>&1 </dev/console

LINES=0

rm -f $HDSTORE

for count in `cat $disks_choice` ; do
        LINES=$[LINES+1]
done

LINES=$[LINES/2]

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
  --radiolist "Please choose the Harddisk (spacebar to select) to run cfdisk for" 25 60 $LINES \
  $(cat $disks_choice | sed 's:$: off:') 2> $HDSTORE

case $? in
  0)
	if [ "$UID" == "0" ] && [ ! -z "`cat $HDSTORE`" ] ; then
		( /sbin/cfdisk /dev/`cat $HDSTORE` )
		wait
		. $TOP_DIR/common/detect-valid-partitions.sh > /dev/null # || abort_on_error "Cannot access your disk drives properly"
		exec >/dev/console 2>&1 </dev/console
	fi
	;;
  1)
	sleep 0.2
	;;
  255)
	cancel_install
	;;
esac

}

#
# This script lets you choose partitions
#


select_partition(){

LIMIT="$2"

source /var/yis/settings

LINES=0

rm -f $PMENU
rm -f $PSTORE

for part in `cat $DISKS | sed 's:/dev/::1'` ; do
	size=$(cat /proc/partitions | grep $part | echo $[`awk '{print $3}'`/1024])

[ ! -z "$LIMIT" ] && [ "$size" -lt "$LIMIT" ] && continue

	if [ "$size" -gt "50" ] ; then
		[ "$size" -lt "100000" ] && [ "$size" -gt "9999" ] && size="0$size"
		[ "$size" -lt "10000" ] && [ "$size" -gt "999" ] && size="00$size"
		[ "$size" -lt "1000" ] && [ "$size" -gt "99" ] && size="000$size"
		[ "$size" -lt "100" ] && [ "$size" -gt "9" ] && size="0000$size"
		echo -n $part >> $PMENU
		echo -n " ${size}_MByte" >> $PMENU
 		echo " off" >> $PMENU
	fi

for line in `cat $SKIP_THEM 2>/dev/null` ; do
	perl -ni~ -e "print unless /$line/" $PMENU
done

done

for count in `cat $PMENU` ; do
        LINES=$[LINES+1]
done

LINES=$[LINES/3]

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
  --radiolist "Press the SPACE key to select partition for : $1 "  25 60 $LINES $(cat $PMENU) 2> $PSTORE

}


select_filesystem(){

source /var/yis/settings

rm -f $FS_MENU
rm -f $FS_STORE

LINES=6

cp -a $FILESYSTEMS $FS_MENU

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
--radiolist "Please choose the filesystem you want to use" 25 60 $LINES \
ext2            "Standard Linux Filesystem              " off \
ext3            "Journaling file system                 " off \
reiserfs        "Journaling file system                 " off \
reiser4         "Experimental journaling file system    " off \
xfs             "Journaling file system                 " on \
2> $FS_STORE

}

format_partition(){

source /var/yis/settings

echo "Got this device : $1"
echo "Chosen filesystem is: `cat $TMP/fs_choice`"

mkfs="mkfs.`cat $TMP/fs_choice`"
fsck="fsck.`cat $TMP/fs_choice` -p -q"

[ "$mkfs" == "mkfs.xfs" ] && appendix=" -qf " && fsck=`which fsck.xfs` 
[ "$mkfs" == "mkfs.reiserfs" ] && appendix=" -q " && fsck="`which fsck.reiserfs` -q -y"
[ "$mkfs" == "mkfs.reiser4" ] && appendix=" -y " && fsck="`which fsck.reiser4` --fix -q -y"

if [ -n "$mkfs" ] ; then
	run_mkfs="`which $mkfs` $appendix"
else
	abort_on_error "Missing executable to format partition : $1 with `cat $TMP/fs_choice`"
fi
	
echo "Preparing $1"

for dev in `cat /proc/partitions | awk '{print $4}' | grep [h,s]*[1-9]` ; do
	umount -l /dev/$dev > /dev/null 2>&1
done

[ -n "`cat /proc/mounts | grep ^\$1`" ] && abort_on_error "$1 could not be unmounted cleanly"

sleep 0.2


if [ "$UID" == "0" ] ; then
	( $run_mkfs $1 > /dev/null )
	wait || abort_on_error "formatting $1" 
	( [ -n "$fsck" ] && $fsck $1 > /dev/null 2>&1 )
	wait || abort_on_error "Media verification failed $1"
fi

sleep 0.2

}

select_mbr(){

source /var/yis/settings

LINES=0

for count in `cat $disks_choice` ; do
        LINES=$[LINES+1]
done

LINES=$[LINES/2]

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title "Bootloader Installation" \
  --radiolist "Please choose the Harddisk (spacebar to select) to install the bootloader, too. If you choose cancel no bootloader will be installed." 25 60 $LINES \
  $(cat $disks_choice | sed 's:$: off:') 2> $HDSTORE

}


# From here we start , and also can start over if requested
# This should be the only point to work without var ,

source /var/yis/settings
rm -f $SKIP_THEM

# How can we select to go back a step without creating a circle ?

run_cfdisk

if [ -z "`cat $DISKS`" ] ; then
	echo "$(color ltgreen black)No partitions available, please rerun the install "
	echo "and choose to run cfdisk to setup your harddisk properly"
	echo "You need at least one partition with 3 GB to install Yoper "
	color off
	exit 1
fi


select_partition root 3072
[ -z "`cat $PSTORE`" ] && cancel_install

cp -a $PSTORE $TMP/root_partition_choice
cat $TMP/root_partition_choice >> $SKIP_THEM
echo "" >> $SKIP_THEM

select_partition home 99
cp -a $PSTORE $TMP/home_partition_choice
cat $TMP/home_partition_choice >> $SKIP_THEM
echo "" >> $SKIP_THEM

select_partition swap 256
cp -a $PSTORE $TMP/swap_partition_choice
cat $TMP/swap_partition_choice >> $SKIP_THEM
echo "" >> $SKIP_THEM

select_filesystem
[ -z "`cat $FS_STORE`" ] && cancel_install
cp -a $FS_STORE $TMP/fs_choice

HOME_DEV=`cat $TMP/home_partition_choice`
[ -a "$LINUX_PARTITIONS" ] && [ ! -z "$HOME_DEV" ] && \
if [ ! -z "`cat $LINUX_PARTITIONS 2> /dev/null | grep $HOME_DEV`" ] ; then
	$DIALOG --backtitle "YOUR Operating System Installation Program" --title Partitioning --yesno \
	"Your home device seems to already have a unix file system. \
	If you want to format your drive, please choose YES. \
	If you want to keep your data on the disk please choose (NO) " \
	25 60 2> $PSTORE

	case $? in
  		0)
		echo "Format home"
		echo "1" > $TMP/format_home
		;;
  		1)
		echo "Don't format home"
		rm -f $TMP/format_home
		;;
  		255)
		cancel_install
		;;
	esac

else

	$DIALOG  --backtitle "YOUR Operating System Installation Program" --title Partitioning --yesno \
	"Your home device seems to have not a unix file system. \
	If you want to format your drive, please choose YES. \
	If you want to keep the partition as is please choose NO " \
	25 60 2> $PSTORE

	case $? in
  		0)
		echo "Format home"
		echo "1" > $TMP/format_home
		;;
  		1)
		echo "Don't format home"
		rm -f $TMP/format_home
		;;
  		255)
		cancel_install
		;;
	esac

fi

if [ ! -d /ramdisk ] ; then
	echo " "
	echo "$(color ltred black) Missing required ressource : /ramdisk ."
	echo "$(color ltred black) Are you really running the install cd ?"	
	color off
	exit 1
else
	( umount /ramdisk/YIS/root/proc > /dev/null 2>&1
	  umount /ramdisk/YIS/root/sys > /dev/null 2>&1
	  umount /ramdisk/YIS/root > /dev/null 2>&1 )
	wait

	[ "$UID" == "0" ] && rm -rf /ramdisk/YIS/root/*
	mkdir -p /ramdisk/YIS/settings/etc/boot
	root_dev="/dev/`cat $TMP/root_partition_choice`" || abort_on_error "Could not find gather your root partition choice"
	format_partition $root_dev
	[ "$UID" == "0" ] && mkdir -p /ramdisk/YIS/root && mount $root_dev /ramdisk/YIS/root > /dev/null || abort_on_error "Mounting installation partition: $root_dev"
fi

[ -z "$root_dev" ] && abort_on_error

if [ "`cat $TMP/fs_choice`" == "reiser4" ] ; then
	OPTIONS="notail,noatime	"
else
	OPTIONS="defaults "
fi

root_line="$root_dev	/	`cat $TMP/fs_choice`	$OPTIONS	1	1 #yoper-root"

#debug
echo "This is your /root : $root_line"
sleep 2

cp -a /KNOPPIX/etc/fstab.sys /ramdisk/YIS/settings/etc/fstab
# cat /etc/fstab | grep ^\/dev/cd >> /ramdisk/YIS/settings/etc/fstab
# cat /etc/fstab | grep ^\/dev/dvd >> /ramdisk/YIS/settings/etc/fstab

grep ^\/dev/cd /etc/fstab >> /ramdisk/YIS/settings/etc/fstab
grep ^\/dev/dvd /etc/fstab >> /ramdisk/YIS/settings/etc/fstab

echo $root_line >> /ramdisk/YIS/settings/etc/fstab

# Formatting home and adding to new /etc/fstab

if 	[ ! -z "`cat $TMP/home_partition_choice 2>/dev/null`" ] && \
	[ "`cat $TMP/format_home 2>/dev/null `" == "1" ] ; then
	home_dev="/dev/`cat $TMP/home_partition_choice`"
	format_partition $home_dev || abort_on_error "formatting $home_dev"

	home_fs=`cat $TMP/fs_choice 2>/dev/null`
	home_line="$home_dev	/home	$home_fs	defaults	0	0 #yoper-home"
	[ -z "$home_fs" ] && home_line="$home_dev	/home	auto	defaults	0	0 #yoper-home"
	echo $home_line >> /ramdisk/YIS/settings/etc/fstab
fi

# Just adding /home to new /etc/fstab

if 	[ ! -z "`cat $TMP/home_partition_choice 2>/dev/null`" ] && \
	[ "`cat $TMP/format_home 2>/dev/null `" != "1" ] ; then
	home_dev="/dev/`cat $TMP/home_partition_choice`"

	home_fs=`cat $LINUX_PARTITIONS | grep ^\$home_dev | awk '{print $2}'`
	home_line="$home_dev	/home	$home_fs	defaults	0	0 #yoper-home"
	[ -z "$home_fs" ] && home_line="$home_dev	/home	auto	defaults	0	0 #yoper-home"
	echo $home_line >> /ramdisk/YIS/settings/etc/fstab
fi

[ -n "$home_dev" ] && echo "This is your /home : $home_line"
sleep 0.2

# Formatting swap, no detection here, what for ?

if [ -n "`cat $TMP/swap_partition_choice`" ] ; then
	swap_dev="/dev/`cat $TMP/swap_partition_choice`"
	/sbin/mkswap $swap_dev 2> /dev/null
	swap_line="$swap_dev	swap	swap	pri=1000	0	0 #swap"
	echo "This is your swap : $swap_line"
	echo $swap_line >> /ramdisk/YIS/settings/etc/fstab
fi

sleep 0.2


INST_ROOT=`cat /ramdisk/YIS/settings/etc/fstab | grep "#yoper-root" | awk '{print $1}'`

[ "`mount | 
grep $INST_ROOT`" != "`mount | grep /ramdisk/YIS/root`" ] && abort_no_partition "Not able to mount new root partition"

sleep 0.5

$TOP_DIR/common/copy-files.sh &

[ -z "$root_dev" ] && abort_on_error

sleep 1

( 
# size delimiter, to match ratio of finalsize to 100%
finsize=6000
oldpercent=0

while [ -a /var/lock/copy.lock ] ; do
	curr_size=`df | grep ^\$root_dev | awk '{print $3}'`
	percent=$[curr_size/finsize]
	[ "$percent" -lt "$oldpercent" ] && percent=$oldpercent
	oldpercent=$percent
	[ "$percent" -gt "100" ] && percent=100
	sleep 5
	echo $percent
done ) | \
$DIALOG --backtitle "YOUR Operating System Installation Program" --title "Copying files" --gauge "Please wait while the files get copied" 10 50 0

wait
sync

sleep 0.2

exec >/dev/console 2>&1 </dev/console

# Bootloader configuration

select_mbr 

clear

# copy finished settings collected through YIS into the mounted root partition


cp -a /dev/*random /ramdisk/YIS/root/dev

(
RETVAL=0
/var/yis/common/copy-settings.sh > /dev/null
[ "$RETVAL" == "1" ] && abort_on_error "Applying basic system configuration failed" 
echo 20

RETVAL=0
/var/yis/common/mkinitrd.sh > /dev/null || abort_on_error "Generating initrdimage failed"
[ "$RETVAL" == "1" ] && abort_on_error "Applying basic system configuration failed" 
echo 40

RETVAL=0
/var/yis/common/install-lilo.sh > /dev/null || abort_on_error "Bootloader installation failed"
[ "$RETVAL" == "1" ] && abort_on_error "Applying basic system configuration failed" 
echo 70


echo 100 ) | \
$DIALOG  --backtitle "YOUR Operating System Installation Program" --title "Initial setup"  --gauge "Preparing installed Yoper system ... " 10 45 0

wait && sync

sleep 1

rm -f /ramdisk/YIS/root/dev/*random

exec >/dev/console 2>&1 </dev/console

$DIALOG  --backtitle "YOUR Operating System Installation Program" --title "Confirm success"  --yesno \
"Do you think everything went ok, then please press YES \
If you want to start over with installation, please press no. \
ESC will bring you to the shell . " 25 60 

case $? in
  0)

exec >/dev/console 2>&1 </dev/console
init 6 
exit 0

;;
  1)

( umount -l /ramdisk/YIS/root/proc > /dev/null 2>&1
  umount -l /ramdisk/YIS/root/sys > /dev/null 2>&1
  umount -l /ramdisk/YIS/root > /dev/null 2>&1 )
wait

exit 0 | /usr/bin/setup
;;
  255)
cancel_install
;;
esac

cancel_install

