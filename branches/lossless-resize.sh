#!/bin/bash

# TODO:
# to be licensed under gpl
# readme

#current usage

#exit codes
#	1:	unexpected error
#	2:	incorrect usage or prerequisites not met (does have error message)
#	3:	chosen partition was not recognized by the program
#	4:	chosen partition was more than 90% full

errormsg(){
echo -e "$1" 1>&2
}

if [ -z "$1" -o -z "$2" ] ; then
	echo "Usage for $0 : "
	echo " 1st argument is device node of partition to change " 1>&2
	echo " 2nd argument is total new size of partition "
	exit 2
fi


if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	errormsg "no config file found"
	exit 2
fi

if [ ! -e "$ALL_PARTITIONS" ] ; then
	if [ -x "$TOP_DIR/common/discinfo.sh" ; then
		 $TOP_DIR/common/discinfo.sh read_all_partitions
	else
		errormsg "Prerequisites not met"
		exit 2
	fi
fi

#give up
[ ! -e "$ALL_PARTITIONS" ] && exit 1

set -x

nonode=0

[ "`echo $1| awk -F '/' '{print $2}'`" != "dev" ] && nonode=1
[ ! -b "$1" ] && nonode=1

if [ "$nonode" == "1" ] ; then
	errormsg "You did not enter a valid device node"
	exit 2
fi

if [ -z "`grep \${1} ${ALL_PARTITIONS}`" ] ; then
	errormsg "Your device node is valid , but cannot be processed by this program"
	exit 3
fi

filesystem="`grep \${1} ${ALL_PARTITIONS} | awk '{print $2}' `"
usedmb="`grep \${1} ${ALL_PARTITIONS} | awk '{print $4}' `"
sizemb="`grep \${1} ${ALL_PARTITIONS} | awk '{print $3}' `"
usageratio=`echo $[$usedmb*100/$sizemb]`

if [ "$usageratio" -gt "90" ] ; then
	errormsg "This partition is used by $usageratio per cent"
	errormsg "Resizing denied !"
	exit 4
fi


exit 0
