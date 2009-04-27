#! /bin/sh -ex

touch /var/lock/format.lock

echo Got the following values :
echo $@

FN_USE=$1
FS_VAL=$2
PART_VAL=$3
TYPE=$4
MOUNT_ROOT="/ramdisk/YIS/root"
MOUNT_HOME="/ramdisk/YIS/home"
MOUNT_BOOT="/ramdisk/YIS/boot"

do_mount(){

run_mount=`which mount`

if [ -e "$run_mount" ] ; then
	if [ "$TYPE" == "Root" ] ; then
		$run_mount $PART_VAL $MOUNT_ROOT
		echo $run_mount $PART_VAL $MOUNT_ROOT
	fi
        if [ "$TYPE" == "Home" ] ; then
                $run_mount $PART_VAL $MOUNT_HOME
		echo $run_mount $PART_VAL $MOUNT_HOME
        fi
        if [ "$TYPE" == "Boot" ] ; then
                $run_mount $PART_VAL $MOUNT_BOOT
		echo $run_mount $PART_VAL $MOUNT_BOOT
        fi
fi
}
	  
do_it(){

if [ "$FS_VAL" == "swap" ] ; then
        run_it=`which mkswap`
else
        run_it=`which mkfs.$FS_VAL`
fi

run_it=`which mkfs.$FS_VAL`

if [ -e "$run_it" ] ; then
	if [ -e "$PART_VAL" ] ; then
		[ "$FS_VAL" == "xfs" ] && run_it="$run_it -qf"
		[ "$FS_VAL" == "reiserfs" ] && run_it="$run_it -q"
		[ "$FS_VAL" == "reiser4" ] && run_it="$run_it -y"
	$run_it $PART_VAL
	fi
fi
}

if [ "$FN_USE" == "Format" ] ; then
	do_it && do_mount
fi

if [ "$FN_USE" == "Mount" ] ; then
	do_mount
fi

echo $run_it $PART_VAL && sleep 2 && rm -f /var/lock/format.lock
