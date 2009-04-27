#! /bin/bash 

LANG=C
source /etc/yis/settings || exit 1

$TOP_DIR/common/add-network-interfaces.sh

chkconfig --del kdmctrl 2>/dev/null

if [ "$ISOTYPE" = "slim" ] ; then

	cd $TOP_DIR/cli
	( ./cli.sh )

else

mkdir -p $TMP

choice=`mktemp`

$DIALOG --backtitle "Yoper Installation or Rescue Mode" --title "Purpose selection" --clear --radiolist " \n  
Do you want to : \n \n
Start the installation, so please choose \n \n
CLI - for a very fast and minimalistic installation,\n
LIVE - explore Yoper on CD / DVD.\n\n
If you want to use the CD-Rom in rescue mode, please press Cancel\n \n \n \n " \
0 0 5 \
"Install Yoper"   	"Installation via a lean dialog interface" off \
"Live CD"		"Live CD with your selected Yoper Desktop" on \
Reboot 			"Reboot the computer" off 2> $choice

#"Xfce4"			"Live CD using the alternative GTK Desktop" off \

result="`cat $choice 2>/dev/null`"

set +x

echo $result

if [ "$result" = "Live CD" ] ; then
	echo "session=live" >> /etc/yis/settings
	cd $TOP_DIR/livecd
	( ./start-live-cd.sh )
elif [ "$result" = "Install Yoper" ] ; then
	cd $TOP_DIR/cli
	( ./cli.sh )
elif [ "$result" = "Reboot" ] ; then
	echo reboot computer
	/sbin/init 6
elif [ -z "$result" ] ; then
	color ltgreen black && clear 
	echo -e "\nNow you're in the Yoper rescue mode, enter '`color ltred black`init 6`color ltgreen black`' to reboot \n \n"
	exit 0
fi

fi

