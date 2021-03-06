#!/bin/sh
#
#  DEFAULT KDE STARTUP SCRIPT ( KDE-3.5 )
#

# When the X server dies we get a HUP signal from xinit. We must ignore it
# because we still need to do some cleanup.
trap 'echo GOT SIGHUP' HUP

PATH=/bin:/usr/bin/:/sbin:/usr/sbin:/usr/X11R6/bin

# Check if a KDE session already is running
if kcheckrunning >/dev/null 2>&1; then
	echo "KDE seems to be already running on this display."
	xmessage -geometry 500x100 "KDE seems to be already running on this display." > /dev/null 2>/dev/null
	exit 1
fi

# Set the background to plain grey.
# The standard X background is nasty, causing moire effects and exploding
# people's heads. We use colours from the standard KDE palette for those with
# palettised displays.
if test -z "$XDM_MANAGED" || echo "$XDM_MANAGED" | grep ",auto" > /dev/null; then
  xsetroot -solid "#000000"
fi

# we have to unset this for Darwin since it will screw up KDE's dynamic-loading
unset DYLD_FORCE_FLAT_NAMESPACE

# in case we have been started with full pathname spec without being in PATH
bindir=`echo "$0" | sed -n 's,^\(/.*\)/[^/][^/]*$,\1,p'`
if [ -n "$bindir" ]; then
  case $PATH in
    $bindir|$bindir:*|*:$bindir|*:$bindir:*) ;;
    *) PATH=$bindir:$PATH; export PATH;;
  esac
fi

# Boot sequence:
#
# kdeinit is used to fork off processes which improves memory usage
# and startup time.
#
# * kdeinit starts the dcopserver and klauncher first.
# * Then kded is started. kded is responsible for keeping the sycoca
#   database up to date. When an up to date database is present it goes
#   into the background and the startup continues.
# * Then kdeinit starts kcminit. kcminit performs initialisation of
#   certain devices according to the user's settings
#
# * Then ksmserver is started which in turn starts
#   1) the window manager (kwin)
#   2) everything in $KDEDIR/share/autostart (kdesktop, kicker, etc.)
#   3) the rest of the session.

# The user's personal KDE directory is usually ~/.kde, but this setting
# may be overridden by setting KDEHOME.

KDEHOME=/var/yis/yis-gui/.kde
test -n "$KDEHOME" && kdehome=`echo "$KDEHOME"|sed "s,^~/,$HOME/,"`

# see kstartupconfig source for usage
mkdir -m 700 -p $kdehome
mkdir -m 700 -p $kdehome/share
mkdir -m 700 -p $kdehome/share/config
cat >$kdehome/share/config/startupconfigkeys <<EOF
kcminputrc Mouse cursorTheme ''
kcminputrc Mouse cursorSize ''
kpersonalizerrc General FirstLogin true
ksplashrc KSplash Theme Default
kcmrandrrc Display ApplyOnStartup false
kcmrandrrc [Screen0]
kcmrandrrc [Screen1]
kcmrandrrc [Screen2]
kcmrandrrc [Screen3]
EOF
/usr/bin/kstartupconfig
#if test $? -ne 0; then
#    xmessage -geometry 500x100 "Could not start kstartupconfig. Check your installation."
#fi
. $kdehome/share/config/startupconfig

# XCursor mouse theme needs to be applied here to work even for kded or ksmserver
if test -n "$kcminputrc_mouse_cursortheme" -o -n "$kcminputrc_mouse_cursorsize" ; then
    kapplymousetheme "$kcminputrc_mouse_cursortheme" "$kcminputrc_mouse_cursorsize"
    if test $? -eq 10; then
        export XCURSOR_THEME=default
    elif test -n "$kcminputrc_mouse_cursortheme"; then
        export XCURSOR_THEME="$kcminputrc_mouse_cursortheme"
    fi
    if test -n "$kcminputrc_mouse_cursorsize"; then
        export XCURSOR_SIZE="$kcminputrc_mouse_cursorsize"
    fi
fi

if test "$kcmrandrrc_display_applyonstartup" = "true"; then
    # 4 screens is hopefully enough
    for scrn in 0 1 2 3; do
        args=
        width="\$kcmrandrrc_screen${scrn}_width" ; eval "width=$width"
        height="\$kcmrandrrc_screen${scrn}_height" ; eval "height=$height"
        if test -n "${width}" -a -n "${height}"; then
            args="$args -s ${width}x${height}"
        fi
        refresh="\$kcmrandrrc_screen${scrn}_refresh" ; eval "refresh=$refresh"
        if test -n "${refresh}"; then
            args="$args -r ${refresh}"
        fi
        rotation="\$kcmrandrrc_screen${scrn}_rotation" ; eval "rotation=$rotation"
        if test -n "${rotation}"; then
            case "${rotation}" in
                0)
                    args="$args -o 0"
                    ;;
                90)
                    args="$args -o 1"
                    ;;
                180)
                    args="$args -o 2"
                    ;;
                270)
                    args="$args -o 3"
                    ;;
            esac
        fi
        reflectx="\$kcmrandrrc_screen${scrn}_reflectx" ; eval "reflectx=$reflectx"
        if test "${refrectx}" = "true"; then
            args="$args -x"
        fi
        reflecty="\$kcmrandrrc_screen${scrn}_reflecty" ; eval "reflecty=$reflecty"
        if test "${refrecty}" = "true"; then
            args="$args -y"
        fi
        if test -n "$args"; then
            xrandr $args
        fi
    done
fi

# Source scripts found in <localprefix>/env/*.sh and <prefixes>/env/*.sh
# (where <localprefix> is $KDEHOME or ~/.kde, and <prefixes> is where KDE is installed)
#
# This is where you can define environment variables that will be available to
# all KDE programs, so this is where you can run agents using e.g. eval `ssh-agent`
# or eval `gpg-agent --daemon`.
# Note: if you do that, you should also put "ssh-agent -k" as a shutdown script
#
# (see end of this file).
# For anything else (that doesn't set env vars, or that needs a window manager),
# better use the Autostart folder.

exepath=`kde-config --path exe | tr : '\n'`

for prefix in `echo "$exepath" | sed -n -e 's,/bin[^/]*/,/env/,p'`; do
  for file in "$prefix"*.sh; do
    test -r "$file" && . "$file"
  done
done

# Activate the kde font directories.
#
# There are 4 directories that may be used for supplying fonts for KDE.
#
# There are two system directories. These belong to the administrator.
# There are two user directories, where the user may add her own fonts.
#
# The 'override' versions are for fonts that should come first in the list,
# i.e. if you have a font in your 'override' directory, it will be used in
# preference to any other.
#
# The preference order looks like this:
# user override, system override, X, user, system
#
# Where X is the original font database that was set up before this script
# runs.

usr_odir=$HOME/.fonts/kde-override
usr_fdir=$HOME/.fonts

# Add any user-installed font directories to the X font path
kde_fontpaths=$usr_fdir/fontpaths
do_usr_fdir=1
do_usr_odir=1
if test -r "$kde_fontpaths" ; then
    savifs=$IFS
    IFS="
"
    for fpath in `grep -v '^[ 	]*#' < "$kde_fontpaths"` ; do
        rfpath=`echo $fpath | sed "s:^~:$HOME:g"`
        if test -s "$rfpath"/fonts.dir; then
            xset fp+ "$rfpath"
            if test "$rfpath" = "$usr_fdir"; then
                do_usr_fdir=0
            fi
            if test "$rfpath" = "$usr_odir"; then
                do_usr_odir=0
            fi
        fi
    done
    IFS=$savifs
fi

if test -n "$KDEDIRS"; then
  kdedirs_first=`echo "$KDEDIRS"|sed -e 's/:.*//'`
  sys_odir=$kdedirs_first/share/fonts/override
  sys_fdir=$kdedirs_first/share/fonts
else
  sys_odir=$KDEDIR/share/fonts/override
  sys_fdir=$KDEDIR/share/fonts
fi

# We run mkfontdir on the user's font dirs (if we have permission) to pick
# up any new fonts they may have installed. If mkfontdir fails, we still
# add the user's dirs to the font path, as they might simply have been made
# read-only by the administrator, for whatever reason.

# Only do usr_fdir and usr_odir if they are *not* listed in fontpaths
test -d "$sys_odir" && xset +fp "$sys_odir"
test $do_usr_odir -eq 1 && test -d "$usr_odir" && (mkfontdir "$usr_odir" ; xset +fp "$usr_odir")
test $do_usr_fdir -eq 1 && test -d "$usr_fdir" && (mkfontdir "$usr_fdir" ; xset fp+ "$usr_fdir")
test -d "$sys_fdir" && xset fp+ "$sys_fdir"

# Ask X11 to rebuild its font list.
xset fp rehash

# Set a left cursor instead of the standard X11 "X" cursor, since I've heard
# from some users that they're confused and don't know what to do. This is
# especially necessary on slow machines, where starting KDE takes one or two
# minutes until anything appears on the screen.
#
# If the user has overwritten fonts, the cursor font may be different now
# so don't move this up.
#
xsetroot -cursor_name left_ptr

# Get Ghostscript to look into user's KDE fonts dir for additional Fontmap
if test -n "$GS_LIB" ; then
    GS_LIB=$usr_fdir:$GS_LIB
    export GS_LIB
else
    GS_LIB=$usr_fdir
    export GS_LIB
fi

# Link "tmp" resource to directory in /tmp
# Creates a directory /tmp/kde-$USER and links $KDEHOME/tmp-$HOSTNAME to it.
lnusertemp tmp >/dev/null

# Link "socket" resource to directory in /tmp
# Creates a directory /tmp/ksocket-$USER and links $KDEHOME/socket-$HOSTNAME to it.
lnusertemp socket >/dev/null

# Link "cache" resource to directory in /var/tmp
# Creates a directory /var/tmp/kdecache-$USER and links $KDEHOME/cache-$HOSTNAME to it.
lnusertemp cache >/dev/null

# In case of dcop sockets left by a previous session, cleanup
dcopserver_shutdown

echo 'startkde: Starting up...'  1>&2

# we removed kpersonalizer check for YIS
# and we also don't want a splash 
case "$ksplashrc_ksplash_theme" in 
  None)
     ;; # nothing
  Simple)
     ;; # nothing
  *)
     ;; # nothing
esac

# certain features such as Konqueror preloading work only with full KDE running
KDE_FULL_SESSION=true
export KDE_FULL_SESSION

# We set LD_BIND_NOW to increase the efficiency of kdeinit.
# kdeinit unsets this variable before loading applications.
LD_BIND_NOW=true kdeinit +kcminit
if test $? -ne 0; then
  # Startup error
  echo 'startkde: Could not start kdeinit. Check your installation.'  1>&2
  xmessage -geometry 500x100 "Could not start kdeinit. Check your installation."
fi

# If the session should be locked from the start (locked autologin),
# lock now and do the rest of the KDE startup underneath the locker.
if test -n "$DESKTOP_LOCKED"; then
  unset DESKTOP_LOCKED # Won't need it any more
  kwrapper kdesktop_lock --forcelock &
  # Give it some time for starting up. This is somewhat unclean; some
  # notification would be better.
  sleep 1
fi

# finally, give the session control to the session manager
# if the KDEWM environment variable has been set, then it will be used as KDE's
# window manager instead of kwin.
# if KDEWM is not set, ksmserver will ensure kwin is started.
# kwrapper is used to reduce startup time and memory usage
# kwrapper does not return usefull error codes such as the exit code of ksmserver.
# We only check for 255 which means that the ksmserver process could not be 
# started, any problems thereafter, e.g. ksmserver failing to initialize, 
# will remain undetected.
test -n "$KDEWM" && KDEWM="--windowmanager $KDEWM"
kwrapper ksmserver $KDEWM 
if test $? -eq 255; then
  # Startup error
  echo 'startkde: Could not start ksmserver. Check your installation.'  1>&2
  xmessage -geometry 500x100 "Could not start ksmserver. Check your installation."
fi

# wait if there's any crashhandler shown
while dcop | grep -q ^drkonqi- ; do
    sleep 5
done

echo 'startkde: Shutting down...'  1>&2

# Clean up
kdeinit_shutdown
dcopserver_shutdown --wait
artsshell -q terminate

echo 'startkde: Running shutdown scripts...'  1>&2

# Run scripts found in $KDEDIRS/shutdown
for prefix in `echo "$exepath" | sed -n -e 's,/bin[^/]*/,/shutdown/,p'`; do
  for file in `ls "$prefix" 2> /dev/null | egrep -v '(~|\.bak)$'`; do
    test -x "$prefix$file" && "$prefix$file"
  done
done

echo 'startkde: Done.'  1>&2
