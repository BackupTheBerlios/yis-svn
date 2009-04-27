#!/bin/bash
# This script is run chrooted in the new yoper installation

chvt 1
tput reset
clear

for file in /etc/yis/firstboot.d/S* ; do
	tput reset
	clear
	[ -n "$file" -a -x "$file" ] && . $file start
done

for file in /etc/yis/firstboot.d/K* ; do
	[ -n "$file" -a -x "$file" ] && . $file stop
done

sed -i -e 's/HWSETUP=yes/HWSETUP=no/g' /etc/sysconfig/yoper
rm --one-file-system -rf /var/tmp/* /tmp/* /yis /settings /none /etc/rcS.d/S99firstboot* /.firstrun 
