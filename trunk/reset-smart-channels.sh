#!/bin/bash -i

# small script to do the initial setup of the smart channels using an external mirrorlist

rm -f /etc/smart/channels/* /var/lib/smart/channels/* /var/lib/smart/config* /var/lib/smart/cache 
smart channel --remove-all -y >/dev/null 2>&1

tmpurl=`mktemp -t`

if test -x /usr/bin/check-mirrors.sh ; then

        ( /usr/bin/check-mirrors.sh | awk '{print $NF}' > $tmpurl 2>/dev/null & ) &

	sleep 20
	
	count=0
	for u in `grep "^http\|^ftyp" $tmpurl | sed "s|yoper/yoper-3.0|yoper/3.1|g"` ; do 
		count=$[count+1]
		test "$count" = "1" && test -n "$u" && baseurl=$u
		test "$count" = "2" && test -n "$u" && mirrorurl1=$u
		test "$count" = "3" && test -n "$u" && mirrorurl2=$u
	done

fi

rm -f $tmpurl

test -z "$baseurl" && baseurl=ftp://ftp.yoper.com/pub/yoper/3.1

#rpm-sys should be in distro.py

echo "
[yoper-3.1]
type = apt-rpm
baseurl=$baseurl
components = rocketfuel dynamite
" > /etc/smart/channels/yoper-3.1.channel

LANG=C && echo y | smart channel --add /etc/smart/channels/yoper-3.1.channel

test -n $mirrorurl1 && smart mirror --add $baseurl $mirrorurl1
test -n $mirrorurl2 && smart mirror --add $baseurl $mirrorurl2

killall wget

LANG=C && echo y | smart-update

