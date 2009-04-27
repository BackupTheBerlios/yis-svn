#!/bin/bash
#This installer shall be licensed under the GPL v2

if [ /etc/yis/settings ] ; then
	source /etc/yis/settings
	mkdir -p $TMP
else
	echo -e "$(color ltgreen black)Installation CD corrupted, aborting installation ! \n"
	exit 1
fi

( killall cp > /dev/null 2>&1 )

( umount -l ${INST_ROOT}/proc > /dev/null 2>&1
  umount -l ${INST_ROOT}/sys > /dev/null 2>&1
  umount -l ${INST_ROOT} > /dev/null 2>&1 )
wait

for rem in `ls -1d $mntdir/* > /dev/null 2>&1` ; do 
	umount -l $rem > /dev/null 2>&1 &
done

umount -a

[ "$1" = "debug" ] && set -x 

[ ! -d "$TOP_DIR" ] && echo -e "$(color ltgreen black)Installation CD corrupted, aborting installation ! \n" && exit 1

cancel_install(){

( umount -l ${INST_ROOT}/proc > /dev/null 2>&1
  umount -l ${INST_ROOT}/sys > /dev/null 2>&1
  umount -l ${INST_ROOT} > /dev/null 2>&1 )
wait

echo " "
echo " "
echo "$(color ltgreen black)You have chosen to cancel Yoper installation ... "
echo ""
echo "$(color ltgreen black)When you want to try again enter $(color ltred black)yoperinstall "
echo ""

quit_function

}

abort_on_error(){

sleep 3

echo " "
[ -n "$1" ] && echo -e "$(color ltgreen black)The installation failed : "$1" !"
[ -z "$1" ] && echo "$(color ltgreen black)The installation failed for an unknown reason. "
echo ""
echo "$(color ltgreen black)When you want to try again enter $(color ltred black)yoperinstall "
echo ""

quit_function

}

quit_function(){

rm -f $TMP/* >/dev/null 2>&1
find $TMP/ -xdev -type f -exec rm -f '{}' \;

color off

( umount -l ${INST_ROOT}/proc > /dev/null 2>&1
  umount -l ${INST_ROOT}/sys > /dev/null 2>&1
  umount -l ${INST_ROOT} > /dev/null 2>&1 )
wait

exit 1 | killall cli.sh
exit 1

}

#
# This scripts gathers the harddisk and partition information and if run as root also the linux partitions
# 

func_gather_disc_info(){

. $TOP_DIR/common/discinfo.sh list_hdds > /dev/null 2>&1 
. $TOP_DIR/common/discinfo.sh generate_device_map > /dev/null 2>&1 
. $TOP_DIR/common/discinfo.sh read_all_partitions > /dev/null 2>&1 

}

run_cfdisk(){

source /etc/yis/settings

rm -f $disks_choice
$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
--infobox "\nGathering information about your storage media ..." 0 0
func_gather_disc_info

exec >/dev/console 2>&1 </dev/console

[ -z "`cat $disks_choice`" ] && abort_on_error "Could not detect any hard disk."

LINES=0

rm -f $HDSTORE

for count in `cat $disks_choice` ; do
        LINES=$[LINES+1]
done

LINES=$[LINES/2]

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
  --ok-label "Proceed Installation" --no-cancel \
  --radiolist \
"\nIf you need to repartition your hard drives
\nuse the up / down arrow keys to navigate and select with spacebar.
\nIt might be necessary to reboot after repartitioning.
\n
\nIf you want to use an existing partion,
\njust press enter without selecting any hard disk.
\n" 25 60 $LINES \
  $(cat $disks_choice | sed 's:$: off:') 2> $HDSTORE

case $? in
  0)
	if [ "$UID" = "0" ] && [ ! -z "`cat $HDSTORE`" ] ; then
		( /sbin/cfdisk /dev/`cat $HDSTORE` )
		wait
		echo "Rereading partitions, this might take a while ..."
		echo "On error the system will reboot immediately"
		echo "$(color ltgreen black)You can safely start over with installation after reboot"
		color off
		/usr/sbin/partprobe >/dev/null 2>&1 || ( sleep 5 ; /sbin/reboot )
		/sbin/start_udev >/dev/null 2>&1
		func_gather_disc_info

		exec >/dev/console 2>&1 </dev/console
		[ -z "`cat $disks_choice`" ] && abort_on_error "Cannot access your disk drives properly"
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

select_partition(){

LIMIT="$2"
source /etc/yis/settings
LINES=0
rm -f $PMENU $PSTORE

[ -z "`cat $PARTITIONS 2>/dev/null`" ] && abort_on_error "Missing storage media info"

for part in `cat $PARTITIONS` ; do

       #after rerunning we might have out of date information here
       if [ -n "$part" -a -a "$part" ] ; then

	pd=`echo $part | cut -c1-8`

	if [ -n "`fdisk -l $pd 2>/dev/null| grep "^\$part" | grep -vi Extended`" ] ; then
		size=`fdisk -s $part 2>/dev/null`
		
		if [ "$size" -gt "0" ] ; then
			size=$[size/1024]
		else
			size=
		fi
	
		[ ! -z "$LIMIT" ] && [ -n "$size" ] && [ "$size" -lt "$LIMIT" ] && continue

	if [ -n "$size" ] && [ "$size" -gt "50" ] ; then

		while [ "`echo $size | wc -m`" -lt "9" ] ; do
			size="0$size"
		done

		echo -n $part >> $PMENU
		echo -n " ${size}_MByte" >> $PMENU
 		#if [ "$LINES" = "0" ] && [ "$1" = "root" ] ; then
		#	echo " on" >> $PMENU
		#else
			echo " off" >> $PMENU
		#fi
		LINES=$[LINES+1]
	fi
	fi
	fi
done

for line in `cat $SKIP_THEM 2>/dev/null | sed 's|/dev/||g'` ; do
	[ -n "$line" ] && sed -i -e "/$line/d" $PMENU
	LINES=$[LINES-1]
done

rm -f $PSTORE

if [ -z "`cat $PMENU 2>/dev/null`" ] ; then
	[ "$1" = "root" ] && abort_on_error "No partitions with at least "$2" MB found. Please run cfdisk in the installer!"
else

if [ "$LINES" -gt "0" ] ; then

if [ "$1" = "root" ] ; then

msg="
\nPlease select your system partition.
\n
\nThis is the place where Yoper will be operating from.
"

fi

if [ "$1" = "swap" ] ; then
msg="
\nYou can optionally select a swap partition.
\nIt will be used to cache data if you run out of RAM.
\n
\nThis choice is optional.
\nLeave unchecked if you don't want it.
"

fi

if [ "$1" = "home" ] ; then

msg="
\nYou can optionally select a home partition.
\nIt will be used to store your own data like 
\ndocuments, pictures and whatever you choose.
\n
\nIt is recommended to choose one. It keeps your
\nfiles completely seperated from the operating system.
\n
\nThis choice is optional.
\nLeave unchecked if you don't want it.
"

fi

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title Partitioning \
--ok-label "Proceed With Installation" --no-cancel \
--radiolist \
"
$msg
\n
\nYou can check and confirm your settings before the installation actually proceeds.
\n
"  30 58 $LINES $(cat $PMENU) 2> $PSTORE 

fi

fi

}

select_filesystem(){

source /etc/yis/settings

rm -f $FS_MENU $FS_STORE

LINES=6

$DIALOG --backtitle  "YOUR Operating System Installation Program" \
--title "Standard File System"  --ok-label "Proceed Installation" --no-cancel \
--radiolist "Please choose the filesystem you want to use.\n" 25 60 $LINES \
ext2            "Standard Linux Filesystem              " off \
ext3            "Journaling file system                 " off \
reiserfs        "Journaling file system                 " off \
xfs             "Journaling file system                 " on \
2> $FS_STORE

}

format_partition(){

source /etc/yis/settings

#echo "Got this device : $1"
#echo "Chosen filesystem is: `cat $TMP/fs_choice`"

mkfs="mkfs.`cat $TMP/fs_choice`"
fsck="fsck.`cat $TMP/fs_choice` -p -q"

[ "$mkfs" = "mkfs.xfs" ] && appendix=" -qf " && fsck=`which fsck.xfs` 
[ "$mkfs" = "mkfs.reiserfs" ] && appendix=" -q " && fsck="`which fsck.reiserfs` -q -y"

if [ -n "$mkfs" ] ; then
	run_mkfs="`which $mkfs` $appendix"
else
	abort_on_error "Missing executable to format partition : $1 with `cat $TMP/fs_choice` filesystem."
fi
	
#echo "Preparing $1"

for dev in `fdisk -l 2>/dev/null|grep ^\/dev | awk '{print $1}'` ; do
	umount -l /dev/$dev > /dev/null 2>&1
done

[ -n "`cat /proc/mounts | grep ^\$1`" ] && abort_on_error "$1 could not be unmounted cleanly"

sleep 0.2

if [ "$UID" = "0" ] ; then
	$run_mkfs $1 >/dev/null 2>&1 || abort_on_error "formatting $1" 
	( [ -n "$fsck" ] && $fsck $1 > /dev/null 2>&1 )
	wait || abort_on_error "Media verification failed $1"
fi

sleep 0.2

}


# From here we start , and also can start over if requested
# This should be the only point to work without var ,

source /etc/yis/settings

# some cleanup
find $TMP/ -xdev -type f -exec rm -f '{}' \;


$DIALOG --backtitle "YOUR Operating System Installation Program" --title "DISCLAIMER" \
--yes-label "I agree and want to proceed" --no-label "I do not agree and want to quit" --yesno " \
\n \n By pressing YES you agree: \n \n
YOPER(TM) LIMITED AND YOPER(TM) HOLDINGS LIMITED DISCLAIM ALL WARRANTIES, EXPRESS OR
IMPLIED, WITH REGARD TO THIS SOFTWARE, INCLUDING WITHOUT LIMITATION
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, \nAND IN NO EVENT SHALL YOPER LIMITED AND YOPER HOLDINGS LIMITED BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, TORT (INCLUDING NEGLIGENCE) OR STRICT LIABILITY,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.\n
- The source code for some software on this CD is available via the\n  appropriate maintainers website \n
  and also via  the apt update service.\n
- Yoper(TM) is distributed under the GPL (www.gnu.org).\n
- Yoper(TM) is a Trademark of Yoper(TM) Holdings Limited.\n \n" 25 75

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



$DIALOG --backtitle "YOUR Operating System Installation Program"  --title "Install Media Verfication" \
        --yes-label "Check my installmedia"  --defaultno --no-label "Skip Media Check" --yesno \
"Would you like to check the integrity of the installfiles?
\nThis will allow you to ascertain if the iso you downloaded is corrupt or not.\n
\nOnly do this if you have issues installing, since it will take some time. " 15 65

case $? in
  0)
echo "Checking Installation Media ... "
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

# How can we select to go back a step without creating a circle ?

run_cfdisk

[ -z "`cat $PARTITIONS`" ] && abort_on_error "No partitions available!\nPlease rerun the install \
and choose to run cfdisk to setup your harddisk properly.\n\
You need at least one partition with 2 GB to install Yoper."

rm -f $TMP/*partition_choice

select_partition root 2000
[ -z "`cat $PSTORE`" ] && cancel_install

cp -a $PSTORE $TMP/root_partition_choice
cat $TMP/root_partition_choice >> $SKIP_THEM
echo "" >> $SKIP_THEM

select_partition home 99

if [ -b `cat $PSTORE 2>/dev/null` ] ; then
	cp -a $PSTORE $TMP/home_partition_choice
	cat $TMP/home_partition_choice >> $SKIP_THEM
	echo "" >> $SKIP_THEM
fi


select_partition swap 128
if [ -b `cat $PSTORE 2>/dev/null` ] ; then
	cp -a $PSTORE $TMP/swap_partition_choice
	cat $TMP/swap_partition_choice >> $SKIP_THEM
	echo "" >> $SKIP_THEM
fi

select_filesystem
[ -z "`cat $FS_STORE`" ] && cancel_install
cp -a $FS_STORE $TMP/fs_choice

HOME_DEV=`cat $TMP/home_partition_choice`

if [ -n "$HOME_DEV" ] ; then

. $TOP_DIR/common/discinfo.sh read_linux_partitions > /dev/null 2>&1 

if [ -n "`cat $LINUX_PARTITIONS 2> /dev/null | grep $HOME_DEV`" ] ; then
	$DIALOG --backtitle "YOUR Operating System Installation Program" --title Partitioning \
	--yes-label "Erase my home drive" --no-label "Keep my data" --defaultno --yesno \
	"Your home device seems to already have a unix file system. \
	Do you want to format your home drive or keep the data on it? " \
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
	$DIALOG  --backtitle "YOUR Operating System Installation Program" --title Partitioning \
	--yes-label "Erase my home drive" --no-label "Keep my data" --yesno \
	"Your home device does not seem to have a unix file system. \
	It is therefore recommended to format your home drive." 25 60 2> $PSTORE

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

fi

# Bootloader configuration
rm -f $HDSTORE

root_dev="`cat $TMP/root_partition_choice`" || abort_on_error "Could not gather your root partition choice"
root_fs=`cat $TMP/fs_choice 2>/dev/null` || abort_on_error "Could not gather your root filesystem choice"
bdev="`echo $root_dev | cut -c1-8`"

bootloader=`mktemp`
$DIALOG --backtitle "YOUR Operating System Installation Program"  --title "Bootloader Installation" \
--ok-label "Proceed Installation" --no-cancel \
--radiolist "Please select which bootloader to install into hd0 ." 15 60 5 \
grub            "Default Yoper Bootloader	" on \
lilo            "Fallback bootloader            " off \
none            "I do not want to install any bootloader " off 2> $bootloader
[ -z "`cat $bootloader`" && echo none > $bootloader

hline=
hdev="`cat $TMP/home_partition_choice 2>/dev/null`"
[ -z "$hdev" ] && hline="I do not want a seperate home partition. "

if [ -n "$hdev" ] ; then
	if 	[ "`cat $TMP/format_home 2>/dev/null`" = "1" ] ; then
		hfs=`cat $TMP/fs_choice 2>/dev/null`
		hline="I want to use $hdev with ${hfs}-filesystem as home partition and delete any existing data on this partition."
	else
		hfs=`cat $LINUX_PARTITIONS | grep ^\$hdev | awk '{print $2}'`
		hline="I want to use $hdev with ${hfs}-filesystem as home partition and keep existing data on this partition."
	fi
fi

sdev="`cat $TMP/swap_partition_choice`"

if [ -n "$sdev" ] ; then
	sline="I want to use $sdev as swap partition for Yoper."
else
	sline="I do not want to use any swap partition for Yoper"
fi

bootloader=`cat $bootloader | cut -c0-4 2>/dev/null`
if [ "$bootloader" != "none" ] ; then
	bline="I want to install $bootloader as the Yoper bootloader into hd0. "
	[ "$bootloader" = "grub" ] && bline2="Note:\n\nIf grub installation fails it will fall back to lilo instead. "
else
	bline="I do not want to install any bootloader."
	bline2="I will setup the bootloader myself."
fi

mychoice=`mktemp -t`
echo -e "\nThese are my Yoper Installation Settings:\n\n" > $mychoice
echo "My primary Yoper System Partition will be $root_dev using ${root_fs}. Any data on $root_dev will be deleted." >> $mychoice
echo -e "\n${hline}" >> $mychoice
echo -e "\n${sline}" >> $mychoice
echo -e "\n${bline}" >> $mychoice
echo -e "\n${bline2}\n" >> $mychoice
echo -e "\n"  >> $mychoice

$DIALOG --backtitle "YOUR Operating System Installation Program"  --title "Confirm your choices" \
--yes-label "Yes, I want to use these settings" --no-label "I do not want to use these settings." --yesno \
"`cat $mychoice`" 0 0

case $? in
	0)
	#echo "Proceed Installation"
	;;
	1)
	exit 0 | /usr/sbin/yoperinstall
	exit 0
	;;
	*)
	cancel_install
	;;
esac

if [ ! -d /ramdisk ] ; then
	echo " "
	echo "$(color ltred black) Missing required resource : /ramdisk ."
	echo "$(color ltred black) Are you really running the install cd ?"	
	color off
	exit 1
else
	( umount ${INST_ROOT}/proc > /dev/null 2>&1
	  umount ${INST_ROOT}/sys > /dev/null 2>&1
	  umount ${INST_ROOT} > /dev/null 2>&1 )
	wait

	[ "$UID" = "0" ] && rm -rf ${INST_ROOT} && mkdir -p ${INST_ROOT}
	mkdir -p /ramdisk/YIS/settings/etc/boot
	[ -z "$root_dev" ] && abort_on_error "Could not gather your root partition choice"
	format_partition $root_dev
	[ "$UID" = "0" ] && mkdir -p ${INST_ROOT} && mount $root_dev ${INST_ROOT} > /dev/null || abort_on_error "Mounting installation partition: $root_dev"
fi

[ -z "$root_dev" ] && abort_on_error

OPTIONS=" defaults "
[ "$root_fs" = "xfs" ] && OPTIONS=" defaults,noatime,nodiratime,logbufs=8 "

root_line="$root_dev	/	$root_fs	$OPTIONS	1	1 #yoper-root"

#debug
#echo "This is your /root : $root_line"
sleep 0.2

cp -a /YOPER/etc/fstab.sys /ramdisk/YIS/settings/etc/fstab
grep ^\/dev/cd /etc/fstab >> /ramdisk/YIS/settings/etc/fstab
grep ^\/dev/dvd /etc/fstab >> /ramdisk/YIS/settings/etc/fstab

#change references to /mnt to /media
#sed -i -e 's|\/mnt/|\/media/|g' /ramdisk/YIS/settings/etc/fstab

echo $root_line >> /ramdisk/YIS/settings/etc/fstab

# Formatting home and adding to new /etc/fstab

if 	[ ! -z "`cat $TMP/home_partition_choice 2>/dev/null`" ] && \
	[ "`cat $TMP/format_home 2>/dev/null `" = "1" ] ; then
	home_dev="`cat $TMP/home_partition_choice`"
	format_partition $home_dev || abort_on_error "formatting $home_dev"

	home_fs=`cat $TMP/fs_choice 2>/dev/null`
	home_line="$home_dev	/home	$home_fs	$OPTIONS	0	0 #yoper-home"
	[ -z "$home_fs" ] && home_line="$home_dev	/home	auto	defaults	0	0 #yoper-home"
	echo $home_line >> /ramdisk/YIS/settings/etc/fstab
fi

# Just adding /home to new /etc/fstab

if 	[ ! -z "`cat $TMP/home_partition_choice 2>/dev/null`" ] && \
	[ "`cat $TMP/format_home 2>/dev/null `" != "1" ] ; then
	home_dev="`cat $TMP/home_partition_choice`"

	home_fs=`cat $LINUX_PARTITIONS | grep ^\$home_dev | awk '{print $2}'`
	home_line="$home_dev	/home	$home_fs	defaults	0	0 #yoper-home"
	[ -z "$home_fs" ] && home_line="$home_dev	/home	auto	defaults	0	0 #yoper-home"
	echo $home_line >> /ramdisk/YIS/settings/etc/fstab
fi

#[ -n "$home_dev" ] && echo "This is your /home : $home_line"
sleep 0.2

# Formatting swap, no detection here, what for ?

if [ -n "`cat $TMP/swap_partition_choice`" ] ; then
	swap_dev="`cat $TMP/swap_partition_choice`"
	/sbin/mkswap $swap_dev 2> /dev/null
	swap_line="$swap_dev	swap	swap	pri=1000	0	0 #swap"
	#echo "This is your swap : $swap_line"
	echo $swap_line >> /ramdisk/YIS/settings/etc/fstab
fi

sleep 0.2

INST_ROOT=`cat /ramdisk/YIS/settings/etc/fstab | grep "#yoper-root" | awk '{print $1}'`

[ "`mount | 
grep $INST_ROOT`" != "`mount | grep ${INST_ROOT}`" ] && abort_no_partition "Not able to mount new root partition"

sleep 0.5

[ -z "$root_dev" ] && abort_on_error

$TOP_DIR/common/copy-files.sh &

echo copy-files > /tmp/progress

cp_pid="`ps ax | grep "cp -a /YOPER" | grep -v grep| awk '{print $1}'`" 
sleep 1

( 
oldpercent=0
# size delimiter, to match ratio of finalsize to 100%
FINSIZE=$[FINSIZE/100]

while [ -a /var/lock/copy.lock ] && [ -d "/proc/${cp_pid}" ] ; do
	curr_size=`df | grep ^\$root_dev | awk '{print $3}'`
	percent=$[curr_size/$FINSIZE]
	[ "$percent" -lt "$oldpercent" ] && percent=$oldpercent
	oldpercent=$percent
	[ "$percent" -gt "100" ] && percent=100
	sleep 5
	echo $percent
done ) | \
$DIALOG --backtitle "YOUR Operating System Installation Program" --title "Copying files" --gauge "\n   Please wait while the files get copied" 10 49 0

wait
sync

sleep 0.2

[ -a /var/lock/copy.lock ] && abort_on_error "Copying files failed"
 
exec >/dev/console 2>&1 </dev/console

source /etc/yis/settings

# copy finished settings collected through YIS into the mounted root partition

cp -a /dev/*random ${INST_ROOT}/dev

unset COPY MKINITRD LILO 

echo copy-settings > /tmp/progress

(
echo 0

RETVAL=0
$TOP_DIR/common/copy-settings.sh > /dev/null
[ "$RETVAL" = "1" ] && COPY=FAIL
echo 20

RETVAL=0
$TOP_DIR/common/mkinitrd.sh > /dev/null || abort_on_error "Generating initrdimage failed"
[ "$RETVAL" = "1" ] && MKINITRD=FAIL
echo 40

GRUB=0

echo write-bootloader-config > /tmp/progress
$TOP_DIR/common/write-bootloader-config.sh || abort_on_error "Could not write bootloader configuration files"
$TOP_DIR/common/discinfo.sh generate_device_map $INST_ROOT/boot/grub/device.map

echo 60
RETVAL=0

if [ "$bootloader" = "grub" ] ; then
	echo grub > /tmp/progress
	echo grub > $INST_ROOT/etc/sysconfig/bootloader
	sh -x $TOP_DIR/common/install-grub.sh > /tmp/grub.log 2>&1 || abort_on_error "Bootloader installation failed"
fi

echo 80

if [ "$bootloader" = "lilo" ] ; then
	echo lilo > /tmp/progress
	echo lilo > $INST_ROOT/etc/sysconfig/bootloader
	$TOP_DIR/common/install-lilo.sh >/tmp/error 2>&1 || abort_on_error "Bootloader installation failed"
	sleep 20
fi

echo 100 ) | \
$DIALOG  --backtitle "YOUR Operating System Installation Program" --title "Initial setup"  --gauge "Preparing installed Yoper system ... " 10 45 0

wait && sync

sleep 1

echo done > /tmp/progress

rm -f ${INST_ROOT}/dev/*random

exec >/dev/console 2>&1 </dev/console

$DIALOG  --backtitle "YOUR Operating System Installation Program" --title "Confirm success"  --yes-label "Reboot Computer" --no-label "Redo Installation" --yesno \
"Finished installation ... .\n
\nI will reboot unless you choose to restart installation. 
ESC will bring you to the shell . " 15 55

case $? in
  0)

exec >/dev/console 2>&1 </dev/console
init 6 
exit 0

;;
  1)

( umount -l ${INST_ROOT}/proc > /dev/null 2>&1
  umount -l ${INST_ROOT}/sys > /dev/null 2>&1
  umount -l ${INST_ROOT} > /dev/null 2>&1 )
wait

exit 0 | $0
;;
  255)
cancel_install
;;
esac

cancel_install

