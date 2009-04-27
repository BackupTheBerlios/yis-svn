#!/bin/bash

root_dev=$1

[ -z "$root_dev" ] && exit 1

sleep 2

( 

# size delimiter, to match ratio of finalsize to 100%

finsize=19500
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
