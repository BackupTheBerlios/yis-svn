#!/bin/bash

modprobe ndiswrapper >/dev/null ||:
modprobe wlan >/dev/null ||:

devlist=`cat /proc/net/dev | grep ":" | awk -F ':' '{ print $1 }' | grep -v "lo\|sit\|irda\|wifi" | awk '{print $1}' | xargs `

for dev in $devlist ; do

#assume some static config happened already, with whatever tool

if [ ! -f "/etc/sysconfig/network-scripts/ifcfg-$dev" ] && [ -n "$dev" ] ; then

echo "DEVICE=$dev
NAME=$dev
ONBOOT=yes
BOOTPROTO=dhcp
" > /etc/sysconfig/network-scripts/ifcfg-$dev 
	
fi

done

