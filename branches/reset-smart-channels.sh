#!/bin/bash -i

# small script to do the initial setup of the smart channels using an external mirrorlist

rm -f /etc/smart/channels/* /var/lib/smart/channels/* /var/lib/smart/config* /var/lib/smart/cache
smart channel --remove-all -y >/dev/null 2>&1


function my_exit () {

rm -f ${urls} ${mirrors} ${m2} >/dev/null 2>&1

exit 0

}

function get_mirrors () {

#migrate mirrorlist
sed -i -e 's|yoper-3.0$|pkg|g' /usr/share/yoper/mirrorlist ${m2}

urls=$(mktemp -t)

for url in `egrep -h "^ftp|^http" /usr/share/yoper/mirrorlist ${m2} | uniq 2>/dev/null`
do
  [ -n "${url}" ] && wget -T 5 -O /dev/null -- ${url}/base/timestamp >/dev/null 2>&1 && echo ${url} >> ${urls} &
done

sleep 5

mirrors=$(mktemp -t)

if [ -n "$(sed -n '1p' ${urls})" ]
then

  /usr/bin/netselect -v -s 3 $(egrep -h "^ftp|^http" ${urls} | sort -u) > ${mirrors}
  baseurl=$(sed -n '1p' ${mirrors} | awk '{print $NF}' 2>/dev/null )
  mirrorurl1=$(sed -n '2p' ${mirrors} | awk '{print $NF}' 2>/dev/null )
  mirrorurl2=$(sed -n '3p' ${mirrors} | awk '{print $NF}' 2>/dev/null )

fi

test -n "$baseurl" || baseurl=ftp://ftp.yoper.com/pub/yoper/pkg

}

function set_channels () {

#rpm-sys should be in distro.py

echo "
[yoper-stable]
type = apt-rpm
baseurl=$baseurl
components = rocketfuel dynamite
" > /etc/smart/channels/yoper-stable.channel

LANG=C && echo y | smart channel --add /etc/smart/channels/yoper-stable.channel

test -n $mirrorurl1 && smart mirror --add $baseurl $mirrorurl1
test -n $mirrorurl2 && smart mirror --add $baseurl $mirrorurl2

killall wget

LANG=C && echo y | smart-update >/dev/null 2>&1 

}

trap my_exit INT TERM EXIT

m2=$(mktemp -t)

#just check whether there's really an internet connection
ping -c 1 www.yoper.com

case $? in
  0)
    get_mirrors
    set_channels
    ;;
  *)
    baseurl=ftp://ftp.yoper.com/pub/yoper/pkg
    set_channels >/dev/null
    ;;
esac

my_exit
