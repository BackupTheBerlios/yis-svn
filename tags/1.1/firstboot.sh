#!/bin/bash
# This script is run chrooted in the new yoper installation

[ -d /KNOPPIX ] && exit 0

#temporary to figure out, why it doesn't take package cd on first attempt
touch /.firstrun

chvt 1
tput reset

clear

(

echo 20

mount /proc >/dev/null 2>&1
mount /sys >/dev/null 2>&1


echo 40


[ ! -f /etc/ssh/ssh_host_key ] && ssh-keygen -P "" -t rsa1 -f /etc/ssh/ssh_host_key > /dev/null

echo 60

[ ! -f /etc/ssh/ssh_host_rsa_key ] && ssh-keygen -P "" -t rsa -f /etc/ssh/ssh_host_rsa_key > /dev/null

echo 80

[ ! -f /etc/ssh/ssh_host_dsa_key ] && ssh-keygen -P "" -t dsa -f /etc/ssh/ssh_host_dsa_key > /dev/null

echo 100

) | \
/usr/bin/dialog --shadow --backtitle "YOUR Operating System Setup Program" --title "Custom setup" --gauge "Preparing installed Yoper system ... " 10 45 70

home=`grep "\/home" /etc/fstab | awk '{print $1}'` || :
[ -n "$home" ] && mount $home /home 2>/dev/null

pwconv

if [ -z "`grep ^root /etc/shadow 2>/dev/null`" ] ; then
	echo "please choose the root password "
	until (passwd);
		 do (echo "Root Password not changed, please retry");
	done;
fi

user=`mktemp`

dialog --backtitle "YOUR Operating System Setup Program" --title "User setup" \
--clear --insecure --shadow --inputbox "Please enter your primary username. Only lowercase letters and numbers are allowed." 13 25 2> $user

# take care that no user is blocking the default UID
perl -ni~ -e "print unless /:1000:/" /etc/passwd

user=`cat $user | tr A-Z a-z | tr -cd [:alnum:]`
/usr/sbin/useradd -u 1000 -g 100 -G 11 -s /bin/bash -m $user

echo "please choose the users password: $user "
until (passwd $user);
 do (clear && echo "User Password not changed, please retry");
done;

pwconv
sleep 0.1

tzselect
alsaconf

sed -i -e 's/HWSETUP=yes/HWSETUP=no/g' /etc/sysconfig/yoper

rm -rf /var/tmp/* /tmp/* /yis /settings /none /etc/rcS.d/S99firstboot* /.firstrun $choice $user



