#!/bin/bash

#shrink-partition.sh
#Author: Tobias Gerschner
#purpose :	wrapper script for parted to resize partitions 
#		allowing lossless repartitioning during Yoper installation

# TODO:
# to be licensed under gpl
# readme

#current usage

#external var's are upper case all internal stuff is lower case

#exit codes
#	1:	unexpected error
#	2:	incorrect usage or prerequisites not met (does have error message)
#	3:	chosen partition was not recognized by the program
#	4:	chosen partition was more than 90% full
#	5:	chosen partition would be more than the given restriction full , can be forced, eventually

errormsg(){
echo -e "$1" 1>&2
}

show_help(){
	echo "Usage for $0 : "
	echo " You have to have NEWSIZE and DNODE in the cmdline " 1>&2
	echo " Optional tell to shrink the start, default is end SHRINK={START/END}"
	exit 2
}

[ -z "$NEWSIZE" -o -z "$DNODE" ] && show_help

if [ -n "`grep \${DNODE} /proc/mounts`" ] ; then
	errormsg "You cannot resize a mounted file system"
	exit 2
fi

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	errormsg "no config file found"
	exit 2
fi

newsize=
newsize=$NEWSIZE
dnode=
dnode=$DNODE
shrink=

if [ -n "$SHRINK" ] ; then
	[ "$SHRINK" == "end" ] && shrink=end
	[ "$SHRINK" == "start" ] && shrink=start
fi

[ -z "$shrink" ] && shrink=end

if [ ! -e "$ALL_PARTITIONS" ] ; then
	if [ -x "$TOP_DIR/common/discinfo.sh" ] ; then
		 $TOP_DIR/common/discinfo.sh read_all_partitions
	else
		errormsg "Prerequisites not met"
		exit 2
	fi
fi

#give up
[ ! -e "$ALL_PARTITIONS" ] && exit 1

nonode=0

[ "`echo $dnode| awk -F '/' '{print $2}'`" != "dev" ] && nonode=1
[ ! -b "$dnode" ] && nonode=1

if [ "$nonode" == "1" ] ; then
	errormsg "You did not enter a valid device node"
	show_help
	exit 2
fi

if [ -z "`grep \${dnode} ${ALL_PARTITIONS}`" ] ; then
	errormsg "Your device node is valid , but cannot be processed by this program"
	exit 3
fi

filesystem="`grep \${dnode} ${ALL_PARTITIONS} | awk '{print $2}' `"
usedmb="$[`grep \${dnode} ${ALL_PARTITIONS} | awk '{print $4}' `/1024]"
sizemb="`grep \${dnode} ${ALL_PARTITIONS} | awk '{print $3}' `"
usageratio="`echo $[$usedmb*100/$sizemb]`"

if [ "$usageratio" -gt "90" ] ; then
	errormsg "This partition is already used by $usageratio %"
	errormsg "Shrinking denied !"
	exit 4
fi

if [ "$newsize" -gt "$sizemb" ] ; then
	errormsg "This tool does shrink only"
	#and the reason is, that's all we need for now
	#furthermore growing a fs needs a far more complex logic to take other partitions into account
	exit 4
fi

#
#set some default values if not given by cmd-line
#

set -x

maxusage=
maxusage=$MAXUSAGE

if [ -z "$maxusage" ] ; then
	[ "$newsize" -lt "5120" ] && maxusage=85
	[ "$newsize" -gt  "5119" ] && maxusage=90
	[ "$newsize" -gt "20480" ] && maxusage=95
fi

#catch false input
[ -n "$maxusage" ] && [ "$maxusage" -gt "99" ] && maxusage=90

#increase that value slightly to be on the save side
usedmb=$[usedmb*51/50]
#calculate the new usage ratio
newusageratio=$[usedmb*100/$newsize]

if [ "$newusageratio" -gt "$maxusage" ] ; then
	errormsg "This partition would be used by $newusageratio %"
	errormsg "The limit was $maxusage"
	errormsg " invoke with MAXUSAGE= to allow resizing"
	exit 5
fi

echo "Success so far "

#small reminder of parted options
# -s scripted / silent / not interactive

#parted has some restrictions how it can resize
[ "$filesystem" == "ext2" ] && shrink=end
[ "$filesystem" == "ext3" ] && shrink=end
[ "$filesystem" == "reiserfs" ] && shrink=end

#we have to get a more appropriate listing of the partitions, to give proper start and end positions
#errormsg "Incomplete script, no resizing will be done for now"
#exit 1

unset $startsize
unset $endsize

disk="`echo $dnode | cut -c1-8`"
partition="`echo $dnode | cut -c9-10`"

#grab the proper start and end value
#using such parsing is ... to be improved
sizemb="`/usr/sbin/parted $disk unit MB print | awk '{print $1,$2,$3,$4}' | grep MB | sed 's|MB||g' | grep ^$partition | awk '{print $1}'`"
startmb="`/usr/sbin/parted $disk unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$partition | awk '{print $2}'`"
endmb="`/usr/sbin/parted $disk unit MB print | awk '{print $1,$2,$3,$4}' |  grep MB | sed 's|MB||g' | grep ^$partition | awk '{print $3}'`"

chknewsize=$[endmb-$startmb]

if [ "$newsize" -gt "$chknewsize" ]  ; then
	errormsg "This tool does shrink only"
	exit 1
fi

if [ "$shrink" == "end" ] ; then
	startsize=$startmb
	endsize=$[startsize+$newsize]
fi

if [ "$shrink" == "start" ] ; then
	endsize=$endmb
	startsize=$[endsize-$newsize]
fi

echo "# /usr/sbin/parted -s $disk resize $partition $startsize $endsize "
