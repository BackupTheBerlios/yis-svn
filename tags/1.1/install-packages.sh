#!/bin/bash
# This script is run chrooted in the new yoper installation

function_ask_for_install(){

dialog --backtitle "YOUR Operating System Installation Program" --title "Software Configuration"  --yes-label "Install more software" --no-label "No more software please" --yesno \
"\nPackage installation ... .\n 

\nIf you want to install additional packages please put the Yoper Installation CD Rom back in your drive and select 'Install more software'.
\n\nIf you want to install packages manually you can skip that part. Please be advised that right now there's really only the bare minimum number of packages installed.
\n\nThe packages will be downloaded from the Internet if you do not insert the CD.

" 20 60

case $? in
  0)

	smart channel --remove-all -y 
	
	sleep 2

	cdrom=`file /dev/cdrom | awk '{print $5}' | cut -c2-9`
	dvd=`file /dev/dvd | awk '{print $5}' | cut -c2-9`
	
	#we add the installationmedia here
	if [ -b /dev/cdrom ] ; then
		mkdir -p /media/cdrom
		mount /dev/cdrom /media/cdrom >/dev/null 2>&1
	fi

	if [ "$cdrom" != "$dvd" ] ; then
		mkdir -p /media/dvd
		mount /dev/$dvd /media/dvd >/dev/null 2>&1
	fi

	ADDP=1
	sleep 1

	;;
  *)
	ADDP=0
	;;
esac

}



function_check_connectivity(){


echo "Testing internet connection:"
check=`mktemp`
lock=`mktemp`
count=0

rm -f $check && (ping -c 1 ftp.yoper.com >/dev/null 2>&1 && rm -f $lock &)

while [ -f $lock ] ; do
	echo -n "."
	sleep 0.5
	count=$[count+1]
	[ "$count" -gt 20 ] && break
done

if [ -f "$lock" ] ; then
	echo -e "\nRemote mirrors unavailable or connection very slow."
else
	echo -e "\nRemote mirrors available."
	ADDP="remote"
fi

}



function_determine_available_channels(){

function_check_connectivity

if [ -n "$(ls /media/cdrom/YOPER/RPMS.rocketfuel/*.rpm 2>/dev/null)" ]  ; then
	ADDP="local"
	echo "Local Installation Media available."
	smart channel --add installmedia type=apt-rpm removable=yes baseurl=/media/cdrom/YOPER components=rocketfuel -y
elif [ -n "$(ls /media/dvd/YOPER/RPMS.rocketfuel/*.rpm 2>/dev/null)" ]  ; then
	ADDP="local"
	echo "Local Installation Media available."
	smart channel --add installmedia type=apt-rpm removable=yes baseurl=/media/dvd/YOPER components=rocketfuel -y
else
	echo "No Local Installation Media found."
fi

sleep 2

}



function_select_and_install(){

choice=`mktemp`

dialog --backtitle  "YOUR Operating System Installation Program" \
--title "Software Configuration"  --ok-label "Proceed Installation" --no-cancel \
--checklist 	"Please select which software you want to install. Multiple Selections are possible.\n\n$fetch" 35 60 6 \
kde-base	"Minimal KDE Desktop" 					off \
kde-standard  	"Basic Desktop and further applications." 		on \
multimedia      "Standard Desktop and more mm apps" 			off \
development 	"All you need to build Yoper Packages"			off \
2> $choice 



if [ -n "`cat $choice`" ] ; then

	install=`mktemp`
	echo "#!/bin/bash" > $install
	[ "$ADDP" == "local" ] && \
	cat >> $install << "EOF"

echo "Please press enter to proceed,"
echo "Starting the package installation may take a while ... "
EOF
	echo -en "smart update\nsmart install -y " >> $install
	
	for select in `cat $choice | sed 's|"||g' 2>/dev/null` ; do
		echo -n " y${select} " >> $install 
	done
	echo "" >> $install
	echo "updatedb >/dev/null 2>&1 &" >> $install

	chmod +x $install
	$install && rm -f $install

fi

}



function_how_to_install(){

echo ""
echo "In case you want to get at least a simple desktop,"
echo "connect to the internet and type :"
echo ""
echo "smart update && smart install ykde-base "
echo "/etc/init.d/kdmctrl restart"
echo ""
echo "You can also try adding custom channels via $0 manual"
sleep 5

}



function_firsttime_setup(){


#do we want to install packages at all
function_ask_for_install

if [ "$ADDP" == "1" ] ; then

rc5listbefore=`mktemp`
chkconfig --list |grep "5:on" | awk '{print $1}' > $rc5listbefore

#make sure we have at least the gateway for dns requests
#afraid it does not work in all cases 
if [ -z "`cat /etc/resolv.conf 2>/dev/null`" ] ; then
	gw=`netstat -nr | grep ^0.0.0.0 | awk '{print $2}'`
	[ -n "$gw" ] && echo "nameserver $gw" >> /etc/resolv.conf
fi

ADDP=
#do we have working channels to get packages from?
function_determine_available_channels

if [ "$ADDP" == "local" ] ; then

	fetch="Packages will be installed from CD."
	smart channel --enable installmedia -y >/dev/null 2>&1
	smart channel --disable yoper-3.0 -y >/dev/null 2>&1 
	function_select_and_install

elif [ "$ADDP" == "remote" ] ; then

	fetch="Packages will be downloaded from internet."
	smart channel --disable installmedia -y >/dev/null 2>&1
	smart channel --enable yoper-3.0 -y >/dev/null 2>&1 
	function_select_and_install

else
	echo -e "\n\nNeither remote servers nor local packages available."
	sleep 3
	function_add_local_channel
	function_select_and_install
#coming from [ "$ADDP" == "local" -o "$ADDP" == "remote" ]
fi

#coming from [ "$ADDP" == "1" ] 
else

echo -e "\n\nYou did choose not to install additional packages"

function_how_to_install

#coming from [ "$ADDP" == "1" ] 
fi


smart channel --enable yoper-3.0 -y >/dev/null 2>&1 

#disable unwanted services
/sbin/service wifi-radar stop >/dev/null 2>&1
/sbin/chkconfig --del wifi-radar >/dev/null 2>&1

umount /media/dvd >/dev/null 2>&1
umount /media/cdrom >/dev/null 2>&1

/usr/sbin/ntsysv --level 35

#start services which are new
for service in `chkconfig --list |grep "5:on" | awk '{print $1}' | grep -v -f $rc5listbefore` ;do
	[ -x /etc/rc.d/init./$service ] && /etc/rc.d/init./$service start
done

rm -f $lock $check $install /etc/rc.d/rc5.d/S99YIS-install-packages.sh $rc5listbefore

[ -n "`chkconfig --list |grep "5:on" | grep ^kdmctrl | awk '{print $1}'`" ] && service kdmctrl start

}



function_add_local_channel(){

choice=`mktemp`

dialog --backtitle "YOUR Operating System Software Installation" --title "Please type path\n to your custom repository" --fselect /media 25 25 2>$choice

path=`cat $choice`

if [ -n "$path" ] ; then

rm -f $choice

echo "Looking for repositories in $path ..."

repotype=

#simple rpm-dir, that should work in the worst case
if [ -n "$(ls $path/*.rpm 2>/dev/null)" ]  ; then
	repotype=rpm-dir
fi

#try to detect an apt-rpm repository
if [ -d "$path/base" ] ;then

	components=
	for loc in `ls -1 $path |grep ^RPMS.| awk -F '.' '{print $2}'` ; do
		components="$components $loc"
	done

	repocomponents=
	for verify in `echo $components` ; do
		[ -f "$path/base/pkglist.$verify" ] && repocomponents="$repocomponents $verify"
	done

	[ -n "$repocomponents" ]  && repotype=apt-rpm

fi

if [ -n "$repotype" ] ; then

removable=no
[ "`echo $path | sed "s|^\/media||1"`" != "$path" ] && removable=yes

[ "$repotype" = "rpm-dir" ] && chandescr="local directory containing a loose collection of rpms."
[ "$repotype" = "apt-rpm" ] && chandescr="local directory containing an apt repository."

dialog --backtitle "YOUR Operating System Software Installation" --title "Confirm new channel" --yesno "\n
Please confirm that you want to proceed with these settings:\n
\n
\nYour new datasource is a $chandescr
\n
\nType:................$repotype
\nRemovable media:.....$removable
\npath:................$path
\ncomponents:..........$repocomponents
\n

" 18 75

case $? in

	0)
	name=`mktemp`
	dialog --backtitle "YOUR Operating System Software Installation" --title "Enter Channel Name" --inputbox "Please enter a sane, meaningful name for your software channel" 10 30 2>$name
	channelname=`cat $name`
	rm -f $name

	[ "$removable" = "yes" ] && smartoptions=" removable=yes "

	if [ "$repotype" = "rpm-dir" ] ; then
		smartoptions="$smartoptions path=$path "
	fi
	
	if [ "$repotype" = "apt-rpm" ] ; then
		smartoptions="$smartoptions baseurl=$path components=`echo $repocomponents`"
	fi

	set -x
	smart channel --add $channelname type=$repotype $smartoptions -y && ADDP=local
	set +x

	;;
	*)
	exit 0
	;;
esac


#Sorry no media detected
else

	
	echo "Could not find any channels"
	echo "Please use smart channel --help to determine which options for adding installation sources you have."

	function_how_to_install
	exit 0

fi

#cancel chosen on path selection
else

	echo -e "\naborted ...\n"
	function_how_to_install
	exit 0
	
fi

if [ "$ADDP" == "local" ] ; then

	fetch="Packages will be installed from local channel: $channelname"
	smart channel --disable yoper-3.0 -y >/dev/null 2>&1

elif [ "$ADDP" == "remote" ] ; then

	fetch="Packages will be downloaded from internet."
	smart channel --enable yoper-3.0 -y >/dev/null 2>&1 

else
	echo -e "\n\nNeither remote servers nor local packages available."

	function_add_local_channel
	function_how_to_install
	function_select_and_install
	exit 0
fi


}

[ "$UID" = "0" ] || exit 1


if [ "$1" = "firstboot" ] ; then

	function_firsttime_setup

elif [ "$1" = "manual" ] ; then

	ADDP=
	function_check_connectivity
	function_add_local_channel
	function_select_and_install

else
	echo "If you want to run this script manually please use manual as parameter"
	exit 0
fi
