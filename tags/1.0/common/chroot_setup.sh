#!/bin/bash 
# This script is run chrooted in the new yoper installation

(

mount /proc >/dev/null 2>&1
mount /sys >/dev/null 2>&1

ssh-keygen -P "" -t rsa1 -f /etc/ssh/ssh_host_key > /dev/null 2>&1
echo 80
ssh-keygen -P "" -t rsa -f /etc/ssh/ssh_host_rsa_key > /dev/null 2>&1
echo 90
ssh-keygen -P "" -t dsa -f /etc/ssh/ssh_host_dsa_key > /dev/null 2>&1
echo 100

) | \
/usr/bin/dialog --shadow --backtitle "YOUR Operating System Setup Program" --title "Custom setup" --gauge "Preparing installed Yoper system ... " 10 45 70

home=`grep home /etc/fstab | awk '{print $1}'` || :
[ -n "$home" ] && mount $home /home 2>/dev/null

dialog --backtitle "YOUR Operating System Setup Program" --title "Language chooser" \
        --radiolist "This is the Language chooser \n\
Press SPACE to toggle an option on/off. \n\n\
After this you will have your native keyboard enabled. \
Please download your language pack once you are in KDE. \
After this you can choose your language in the control panel. \
Which Language do you want to choose?" 20 61 10 \
        "english"	"The English Language pack" ON \
        "german"	"The German Language pack" off \
        "french"	"The French Language pack" off \
        "italian"	"The Italian Language pack" off \
        "hungarian"	"The Hungarian Language pack" off \
        "spanish"	"The Spanish Language pack" off \
        "swedish"	"The Swedish Language pack" off \
        "russian"	"The Russian Language pack" off 2> /var/tmp/lang

lang=`cat /var/tmp/lang`

	case $? in
  		0)
		touch /etc/sysconfig/$lang
		echo "LANGUAGE=${lang} " > /etc/sysconfig/lang
		;;
  		1)
		echo ""
		;;
  		255)
		cancel_install
		;;
	esac


echo "please choose the root password:"
until (passwd);
 do (echo "Root Password not changed, please retry");
done;

dialog --backtitle "YOUR Operating System Setup Program" --title "User setup" \
--clear --insecure --shadow --inputbox "Please enter your primary username" 10 25 2> /var/tmp/user

# take care that no user is blocking
perl -ni~ -e "print unless /:1000:/" /etc/passwd

user=`cat /var/tmp/user`
/usr/sbin/useradd -u 1000 -g 100 -G 11 -s /bin/bash -m $user

echo "please choose the users password: $user "
until (passwd $user);
 do (clear && echo "User Password not changed, please retry");
done;

pwconv
sleep 1

tzselect

alsaconf

rm -rf /var/tmp/* /tmp/* /yis /settings /none /etc/rcS.d/S99firstboot

for service in syslog-ng haldaemon kdmctrl cupsd dhclient ; do
	[ -f /etc/rc.d/init.d/$service ] && chkconfig --add $service
done

exit 0

