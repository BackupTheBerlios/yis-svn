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

for p in $(/sbin/pidof /usr/bin/Xorg /usr/bin/kdm /usr/sbin/entranced /usr/bin/xdm /usr/bin/X /usr/bin/gdm) ; do kill -15 $p 2>/dev/null ; sleep 0.5 ; kill -9 $p 2>/dev/null ; done

}

func_kill_any_x

for s in $LIVECD_INIT_DIR/S*
do
	[ -x "$s" ] && $s start
done

sed -i -e '/x:1000:/d' /etc/passwd

[ -n "$(grep ^$LIVEUSER /etc/passwd 2>/dev/null)" ] || /usr/sbin/useradd -u 1000 -g 100 -G 4,11,30,31 -s /bin/bash -m $LIVEUSER

su -c 'mkdir -p ~/.kde/Autostart' $LIVEUSER

sed -i -e '
/root/ c\
root:k9mvZq//NbdDc:14112::::::
' /etc/shadow

echo "$LIVEUSER:k9mvZq//NbdDc:14112::::::" >> /etc/shadow

/etc/init.d/xorg-cfg start

. /etc/rc.d/init.d/functions

ln -s $(which kmix) /home/$LIVEUSER/.kde/Autostart >/dev/null 2>&1

cat > /home/$LIVEUSER/.kde/Autostart/welcome.sh <<"EOF"
kdialog --title "Enjoy using Yoper 3.1" \
--msgbox "\n \
Your feedback is important to us. The Yoper team is always looking for people to discuss and help to improve Yoper.\n\n \
So please don't hesitate to visit us at http://www/yoper.com or drop by in our IRC channel #yoper at irc.freenode.org .\n\n \
Please note your user and root password for the live cd is 'yoper'.\n\n \
If you intend to go online for an extended period of time with the live cd you should change your root password. "
EOF


if [ -f /usr/share/config/kdm/kdmrc ] ; then

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

mv $kdmrc /usr/share/config/kdm/kdmrc

fi

if [ -x "/usr/sbin/entranced" ] ; then

ecore_config -c /etc/entrance_config.cfg -k /entranced/xserver -s "/usr/bin/X -quiet -nolisten tcp vt7"
ecore_config -c /etc/entrance_config.cfg -k /entrance/autologin/mode -i 2
ecore_config -c /etc/entrance_config.cfg -k /entrance/autologin/user -s "$LIVEUSER"
ecore_config -c /etc/entrance_config.cfg -k /entrance/presel/mode -i 0
ecore_config -c /etc/entrance_config.cfg -k /entrance/presel/prevuser -s "$LIVEUSER"

fi

if [ -x /usr/bin/startkde ]  ; then

echo "[Desktop]
Session=kde
" > /home/$LIVEUSER/.dmrc

fi

chmod 755 \
/home/$LIVEUSER/.kde/Autostart/welcome.sh \
/home/$LIVEUSER/.dmrc

chown $LIVEUSER \
/home/$LIVEUSER/.kde/Autostart/welcome.sh \
/home/$LIVEUSER/.dmrc

/etc/init.d/xdm start

while [ -n "$(/sbin/pidof /usr/bin/X 2>/dev/null)" ] ; do
	sleep 1
done ; init 0


