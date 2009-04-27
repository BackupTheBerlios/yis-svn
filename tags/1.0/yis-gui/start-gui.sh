#! /bin/bash

export DISPLAY=:0
export HOME=/root
export PYTHONPATH=/var/yis/yis-gui/modules

cd /var/yis/yis-gui

/usr/sbin/mkxf86config > //dev/null

fix_resolution(){

perl -pi -e 's:Modes "1600x1200":Modes:' $1
perl -pi -e 's:Modes "1400x1050":Modes:' $1
perl -pi -e 's:Modes "1280x1024":Modes:' $1
perl -pi -e 's:Modes "1152x864":Modes:' $1

}

[ -f /etc/X11/XF86Config-4 ] && fix_resolution /etc/X11/XF86Config-4
[ -f /etc/X11/XF86Config ] && fix_resolution /etc/X11/XF86Config

( /var/yis/common/detect-valid-partitions.sh > /dev/null 2>&1 & )
( ./xsession start | sleep 2 && ./kde-yis-init.sh >/dev/null 2>&1 &)
./run-once

wait
sleep 2
/sbin/init 6

