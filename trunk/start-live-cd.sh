#! /bin/bash

[ -f /etc/yis/settings ] && . /etc/yis/settings
[ -z "$LIVEUSER" ] && LIVEUSER=yoperlive

#run some nice to have scripts but do not block progress
(

if [ -n "$LIVECD_INIT_DIR" -a -d "$LIVECD_INIT_DIR" ] ; then
	for script in $LIVECD_INTI_DIR/S* ; do
		. $script >/dev/null 2>&1
	done
fi

) &

func_kill_any_x(){

for p in $(/sbin/pidof /usr/bin/Xorg /usr/bin/kdm) ; do kill -15 $p 2>/dev/null ; sleep 0.5 ; kill -9 $p 2>/dev/null ; done

}

func_kill_any_x

for s in $LIVECD_INIT_DIR/S*
do
	[ -x "$s" ] && $s start
	#debug_sleep
done

[ -f /etc/X11/xorg.conf ] || /usr/sbin/mkxf86config-yoper.sh
[ -n "$(grep ^$LIVEUSER /etc/passwd 2>/dev/null)" ] || /usr/sbin/useradd -u 1000 -g 100 -G 4,11,30,31 -s /bin/bash -m $LIVEUSER

su -c 'mkdir -p ~/.kde/Autostart' $LIVEUSER

#ln -s /usr/share/applications/kde/knetworkmanager.desktop /home/$LIVEUSER/.kde/Autostart/knetworkmanager >/dev/null 2>&1
ln -s $(which kmix) /home/$LIVEUSER/.kde/Autostart >/dev/null 2>&1

cat > /home/$LIVEUSER/.kde/Autostart/welcome.sh <<"EOF"
kdialog --title "Enjoy using Yoper 3.1" \
--msgbox "\n \
Your feedback is important to us. The Yoper team is always looking for people to discuss and help to improve Yoper.\n\n \
So please don't hesitate to visit us at http://www/yoper.com or drop by in our IRC channel #yoper at irc.freenode.org .\n\n \
Please not your root password for the live cd  is 'root'.\n\n \
If you intend to go online for an extended period of time with the live cd you should change your root password. "
EOF

kdmrc=`mktemp`

sed '/^\[X-:0-Core\]/,/^\[X/d' < /usr/share/config/kdm/kdmrc | grep -v "^#" > $kdmrc

echo "

[X-:0-Core]
AutoLoginAgain=false
AutoLoginDelay=0
AutoLoginEnable=true
AutoLoginLocked=false
AutoLoginUser=$LIVEUSER
ClientLogFile=.xsession-errors

" >> $kdmrc

sed -i -e '
/root/ c\
root:ey/9eH5vVeZmU:13972::::::
' /etc/shadow

[ -f /etc/yis/settings ] && . /etc/yis/settings

[ -z "$session" ] && session=kde

echo "[Desktop]
Session=$session
" > /home/$LIVEUSER/.dmrc

chmod 755 \
/home/$LIVEUSER/.kde/Autostart/welcome.sh \
/home/$LIVEUSER/.dmrc

chown $LIVEUSER \
/home/$LIVEUSER/.kde/Autostart/welcome.sh \
/home/$LIVEUSER/.dmrc

kdm -error /tmp/kdm-error.log -debug 6 -config $kdmrc

while [ -n "$(/sbin/pidof /usr/bin/kdm 2>/dev/null)" ] ; do
	sleep 1
done ; init 0


