#! /bin/bash -e

LANG=C

cd /var/yis

/usr/bin/dialog --backtitle "Yoper Installation or Rescue Mode" --title "Purpose selection" --clear \
        --radiolist " \n  
Do you want to : \n \n
Start the installation, so please choose 
\n \n
CLI - for a very fast but minimalistic installation,
\n
GUI - for a comfortable Graphical Installation,
\n
\n
If you want to use the CD-Rom in rescue mode, please press Cancel
\n \n \n \n " \
30 75 5 CLI "Installation via a lean dialog interface" off GUI "Graphical User Interface Installation" on Reboot "Reboot the computer" off 2> /var/tmp/choice

choice="`cat /var/tmp/choice`"

[ -z "$choice" ] && color ltgreen black && clear && echo -e "Now you're in the Yoper rescue mode, enter 'init 6' to reboot \n \n" && exit 0
if [ "$choice" == "GUI" ] ; then
	echo continue with gui
	cd /var/yis/yis-cli
	( /var/yis/yis-gui/start-gui.sh )
elif [ "$choice" == "CLI" ] ; then
	echo continue with cli
	cd /var/yis/yis-cli
	( ./yis-cli.sh )
elif [ "$choice" == "Reboot" ] ; then
	echo reboot computer
	/sbin/init 6
fi

