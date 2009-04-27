#!/bin/bash

modprobe ndiswrapper ||:

if [ -f /etc/ifplugd/ifplugd.conf ] ; then

#
#for d in eth ath wifi wlan ; do
#	for i in `seq 0 9` ; do 
#		dev_current="${d}${i}"
#		ifconfig ${dev_current}) >/dev/null 2>&1 && devlist="$devlist $dev_current"
#	done
#done

devlist=`cat /proc/net/dev | grep ":" | awk -F ':' '{ print $1 }' | grep -v "lo\|sit" | awk '{print $1}' | xargs `

sed -i -e "
/^INTERFACES/ c\
INTERFACES=\"${devlist}\"
" /etc/ifplugd/ifplugd.conf

fi
