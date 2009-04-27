#!/bin/sh

echo '
[macromedia]
type = apt-rpm
name = macromedia software
baseurl = http://macromedia.mplug.org/rpm
components = macromedia
' > /etc/smart/channels/macromedia.channel

LANG=C && echo y | smart channel --add /etc/smart/channels/macromedia.channel
smart-update

smart install flash-plugin -y && /usr/lib/flash-plugin/setup install
