#!/bin/bash
# This script is run chrooted in the new yoper installation


function_check_connectivity(){


#make sure we have at least the gateway for dns requests
#afraid it does not work in all cases 

if [ -z "`cat /etc/resolv.conf 2>/dev/null`" ] ; then
	gw=`netstat -nr | grep ^0.0.0.0 | grep UG | awk '{print $2}'`
	[ -n "$gw" ] && echo "nameserver $gw" >> /etc/resolv.conf
fi

echo "Testing internet connection:"
lock=`mktemp`
count=0

(ping -c 1 www.google.com >/dev/null 2>&1 && rm -f $lock &) &

while [ -f $lock ] ; do
	echo -n "."
	sleep 0.5
	count=$[count+1]
	[ "$count" -gt 20 ] && break
done

if [ -f "$lock" ] ; then
	echo -e "\nRemote mirrors unavailable or connection very slow."
	REMOTE=
else
	echo -e "\nRemote mirrors available."
	REMOTE=true
fi

rm -f $lock

}

function_first_time_setup(){

#
# Initialize package channel and try to achieve connectivity
# ( within reason )
#

rc5listbefore=`mktemp`
chkconfig --list | awk '/5\:on/{print $1}' > $rc5listbefore 2>/dev/null

function_check_connectivity

function_select_and_install

/usr/sbin/ntsysv --level 35

#start services which are new
for service in `chkconfig --list |grep "5:on" | awk '{print $1}' | grep -v -f $rc5listbefore` ;do
	[ -x /etc/rc.d/init./$service ] && /etc/rc.d/init./$service start
done

rm -f $lock $install /etc/rc.d/rc5.d/S99YIS-install-packages.sh $rc5listbefore

[ -n "`chkconfig --list |grep "5:on" | grep ^xdm | awk '{print $1}'`" ] && service xdm start

}


function_select_and_install(){

#
# read packages.info and create menu on the fly
#

inputfile=$CONF_DIR/packages.info

packagemenu=`mktemp`

CNT=0

while [ "$CNT" -lt "99" ] ; do

	let CNT=CNT+1

	if [ "$CNT" -lt "10" ] ; then
		cnt="0$CNT"
	else
		cnt="$CNT"
	fi

	name=`grep "^SET${cnt}_NAME" $inputfile | awk -F '"' '{print $2}' 2>/dev/null`
	desc=`grep "^SET${cnt}_DESC" $inputfile | awk -F '"' '{print $2}' 2>/dev/null`
	list=`grep "^SET${cnt}_LIST" $inputfile | awk -F '"' '{print $2}' 2>/dev/null`

	if [ -n "$name" -a -n "$desc" -a -n "$list" ] ; then
		let lines=lines+1
		echo "\"$name\" \"$desc\" off \\" >> $packagemenu
	else
		break
	fi

done

choice=`mktemp`

#build an extra shell script as this seems to be the only way to get the dialog construct right

packagechoice=`mktemp -t`

cat > $packagechoice <<"EOF"
dialog --backtitle  "YOUR Operating System Installation Program" \
--title "Software Configuration"  --ok-label "Proceed Installation" --no-cancel --trim \
--checklist "Please select which software you want to install. Multiple Selections are possible.\n\n " \
EOF

echo "25 79 $lines \\" >> $packagechoice

sed '/^$/d' < $packagemenu >> $packagechoice

echo "2> $choice
" >>$packagechoice

sh $packagechoice
packageset=$(sed 's| |_|g' $choice)

rm -f $choice $packagemenu $packagechoice

count=$(echo $packageset | awk -F '"_"' '{print NF}')

for c in `seq 1 $count` ; do

p=$(echo $packageset | awk -F '"_"' "{print $`echo $c`}" | sed 's|"||g;s|\\_| |g;s/^[ \t]*//;s/[ \t]*$//')

        if [ -n "$p" ] ; then
                setnr=$(awk -v pat="\"$p\"" -F '"' '$0 ~ pat {print $1}' $inputfile | cut -c1-5 2>/dev/null)
                list=$(awk -v pat="${setnr}_LIST=" -F '"' '$0 ~ pat {print $2}' $inputfile 2>/dev/null)

                plist=$(echo $plist $list| xargs)
        fi
done

[ -n "$plist" ] && smart update && smart install $plist -y && ( updatedb & )

}

#
# SCRIPT STARTS HERE
#

#[ "$UID" = "0" ] || exit 1


#there's no easy way out, but just make sure the script only runs the first time
#this file was created in copy-settings.sh

rm -f /etc/rc.d/rc5.d/S99YIS-install-packages.sh
[ -f /etc/yis/settings ] && source /etc/yis/settings


if [ "$1" = "firstboot" -a "$ISOTYPE" = "slim" ] ; then

	function_first_time_setup
	rpm -q kde-desktop-basic >/dev/null 2>&1 && [ "$REMOTE" = "true" ] && \
	$TOP_DIR/common/install-flash.sh >/dev/null 2>&1 &
	( sleep 10 ; /etc/init.d/xdm start 2>/dev/null & )
		
elif [ "$1" = "manual" ] ; then

	#that's for later
	exit 0
	[ -f /etc/yis/settings ] && source /etc/yis/settings
	function_check_connectivity
	function_add_local_channel
	function_select_and_install
	
#else
	echo "If you want to run this script manually please use manual as parameter"
	exit 0
fi
