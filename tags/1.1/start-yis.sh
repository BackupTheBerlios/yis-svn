#! /bin/bash 

LANG=C
exec >/dev/console 2>&1 </dev/console
source /etc/yis/settings || exit 1

mkdir -p $TMP

$DIALOG --backtitle "Yoper Installation or Rescue Mode" --title "Purpose selection" --clear --radiolist " \n  
Do you want to : \n \n
Start the installation, so please choose \n \n
CLI - for a very fast but minimalistic installation,\n
GUI - for a comfortable Graphical Installation,\n\n
If you want to use the CD-Rom in rescue mode, please press Cancel\n \n \n \n " \
0 0 5 CLI "Installation via a lean dialog interface" off GUI "Graphical User Interface Installation" on Reboot "Reboot the computer" off 2> $choice

result="`cat $choice 2>/dev/null`"

set +x

if [ "$result" == "GUI" ] ; then
	echo GUI Installation not available with this image
	sleep 5
	exit | $0
elif [ "$result" == "CLI" ] ; then
	echo continue with cli
	cd $TOP_DIR/cli
	( ./cli.sh )
elif [ "$result" == "Reboot" ] ; then
	echo reboot computer
	#/sbin/init 6
elif [ -z "$result" ] ; then
	color ltgreen black && clear 
	echo -e "\nNow you're in the Yoper rescue mode, enter '`color ltred black`init 6`color ltgreen black`' to reboot \n \n"
	exit 0
fi


