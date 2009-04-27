#!/bin/bash

configfile=
pwd=`pwd`

# if we want to build auto cd's we don't read local config

if [ "$1" != "auto" ] ; then

#if [ -f /etc/yis/settings ] ; then
#	source /etc/yis/settings
#	configfile=/etc/yis/settings
#fi

if [ -f $pwd/YIS/etc/yis/settings ] ; then
	source $pwd/YIS/etc/yis/settings
	configfile=$pwd/YIS/etc/yis/settings
fi

fi

if [ -z "$configfile" ] ; then
	configfilemsg="\Z1No custom config file, using auto settings ...\Zn .\n"
else
	configfilemsg="\ZnThe active configuration file is : \Z1${configfile}\Zn .\n"
fi

func_abort(){

if [ -n $destination ] ; then
	umount $destination/proc >/dev/null 2>&1 ||:
	rm -f $installcdfiles $yossquashfs 
	#split that to avoid overloading argumentlist
	rm -rf $destination > /dev/null 2>&1 &
	rm -rf /var/lib/mach/roots/yoper-3.0-rocketfuel /var/lib/mach/states/yoper-3.0-rocketfuel > /dev/null 2>&1 &
fi

exit 0

}

func_missing(){

set +x

echo -e "\nPrerequisite not met:\n${1}\n" 1>&2

func_abort

}

func_error(){

set +x

echo -e "\nError occured:\n${1}\n" 1>&2

func_abort

}

# create all variables here to include them in the confirmation screen
[ -z "$PKGCACHEDIR" ] && PKGCACHEDIR=$pwd/pkg-cache
[ -z "$YVERSION" ] && YVERSION=YOS-`date +%Y-%j`
[ -z "$BASEPKGS" ] && BASEPKGS="Linux-PAM MAKEDEV Mesa-libGL ORBit2 SDL aalib acpid alsa-lib alsa-utils apt ash aspell atk audiofile bash beecrypt binutils bzip2 chkconfig ckermit color compat-libstdc.so.5 console-tools consoletype coreutils cpio cracklib curl cyrus-sasl db4 dbus dbus-glib ddcxinfo device-mapper dhcp-client dialog diffutils disktype e2fsprogs eject elfutils esound ethtool expat fam file findutils font-util fuse gawk gdbm gettext glib glib2 glibc gmp grep groff grub gzip hal hdparm hwdata hwinfo hwsetup inetutils infozip iproute iptables kbd krb5 kudzu lame less lilo linux-libc-headers lndir logrotate lua lzo man mc mktemp module-init-tools nano ncurses ndiswrapper ndiswrapper_bcmwl5 neon net-tools newt ntfs-3g ntfsprogs openldap openssh openssl parted patch pciutils pcre perl perl-Archive-Tar perl-HTML-Template perl-NTLM perl-Parse-RecDescent popt powernowd prelink procinfo procps progsreiserfs psmisc pth python python-xml readahead readline rebuildfstab resmgr rpm rpm-python sed shadow sharutils smartpm sqlite strace sudo sysfsutils sysvinit tar tcl tcp_wrappers tcsh texinfo udev unzip usbutils usermode utempter util-linux wget wireless-tools words xfsprogs yaird yoper-rpm-settings yoperbase yoperinitscripts yopermaintain zlib sshfs-fuse pcmcia-utils wpa_supplicant yoper-kde-settings NetworkManager fcron zd1211 psyco dhcdbd reiserfsprogs ntp-date ocfs2-tools reiser4progs "

destination=$BUILDROOT

[ -z "$destination" ] && destination=`mktemp -d`

modprobe squashfs ||:
#only a warning , since it's not really required to build an ISO
if [ -z "`grep squashfs /proc/filesystems`" ] ; then
	echo "Your running kernel does not support squashfs !"
	sleep 3
fi

for exec in which mkisofs mksquashfs wget dialog mach ; do
	[ -z "`which $exec`" ] && func_missing "You do not have $exec installed !"
done

if [ ! -d "$pwd/INSTALL.CD/KNOPPIX" ] ; then
	echo "Need to download archive for CD skeleton ... "
	installcdfiles=`mktemp`
	curl ftp://ftp.yoper.com/pub/devel/source-cache/install-cd-files.tar.bz2 > $installcdfiles
	[ "`md5sum $installcdfiles`" != "45377da2367640d46f270d5a8afd4a40" ] && func_missing "The md5sum of the install cd skeleton archive does not match !"
fi

[ -n "`ls $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel/*.rpm`" ] && cachemsg="Warning: You have some packages left in:\n${pwd}/INSTALL.CD/YOPER \nThose files will be DELETED!"




func_prepare_iso(){

	clear 
	echo "Cleaning out temporary data ..."
	rm -f $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel/*.rpm $pwd/INSTALL.CD/KNOPPIX/KNOPPIX $pwd/INSTALL.CD/boot/vmlinuz $pwd/INSTALL.CD/boot/System.map
	rm -rf /var/lib/mach/roots/yoper-3.0-rocketfuel /var/lib/mach/states/yoper-3.0-rocketfuel > /dev/null 2>&1 && mach -r rocketfuel -f unlock
	sleep 1
	rm -rf /var/lib/mach/roots/yoper-3.0-rocketfuel /var/lib/mach/states/yoper-3.0-rocketfuel > /dev/null 2>&1 && mach -r rocketfuel clean >/dev/null 2>&1
	sleep 1	
	mach -r rocketfuel clean >/dev/null 2>&1 || func_error "Could not clean out mach environment"
	mkdir -p $destination/tmp

	#check available space
	rootspace=`df |grep -m 1 "\/$" |awk '{print $4}'`
	tmpspace=`df |grep -m 1 "\/tmp$" |awk '{print $4}'`

	sleep 0.5

	if [ -z "$tmpspace" ] ; then
		tmpspace=$rootspace
	fi

	#we need at least approx 1 GB to generate an ISO
	if [ "$tmpspace" -gt "1148576" ] ; then
		minimalimage=1
	fi

	#we need at least approx 3 GB to generate a full ISO
	if [ "$tmpspace" -gt "3548576" ] ; then
		stdimage=1
	fi

	ln -s $destination /var/lib/mach/roots/yoper-3.0-rocketfuel

	mach -d -r rocketfuel setup base || func_error "Could not setup mach base"

	cat /etc/resolv.conf > $destination/etc/resolv.conf

	mach -d -r rocketfuel apt-get install $BASEPKGS || func_error "Could not install custom base packages"

	#mach -r rocketfuel apt-get install "kernel#$KVERSIONREL" ||:
	mach -d -r rocketfuel apt-get install yoperinitscripts || func_error "Could not install yoper installer"
	
	#temporary workaround to old yis-cli
	if [ -d "$destination/etc/yis/packages" ] ; then
		rm -rf "$destination/etc/yis/packages"
		echo "ykde-base ykde-standard ymultimedia ydevelopment" > $destination/etc/yis/packages
	fi
	
	if [ -d $pwd/YIS ] ; then
        	cp -aLv $pwd/YIS/* $destination
       	fi

	if [ -f $destination/etc/inittab ] ; then
		cp -aL --suffix .ISO_BAK $destination/etc/yis/inittab.cd $destination/etc/inittab || func_error "Could not replace init configuration file"
	else
		func_error "No regular init config file ( /etc/inittab ) found. "
	fi

	#for convenience 
	find $destination/usr/lib/yis -type f -exec chmod +x '{}' \;

	[ -n "$destination" ] && find $destination/ -name '*.rpm*' -or -name '*~' -exec rm -f '{}' \;

	isosize=`du -s $destination/ |awk '{print $1}'`
	isosize=$[isosize*105/100]

	perl -ni -e 'print unless /FINSIZE/' $destination/etc/yis/settings
	echo "export FINSIZE=$isosize" >> $destination/etc/yis/settings

	return 0

}


func_get_packages(){

cat /etc/resolv.conf > $destination/etc/resolv.conf

rm -f $destination/tmp/prepare

echo "#!/bin/bash -x
BASEURL=${BASEURL}" > $destination/tmp/prepare

cat >> $destination/tmp/prepare << "EOF"

mount -t proc proc /proc

tmp1=`mktemp`
tmp2=`mktemp`

#we have to initialize the distro.py somehow, this works , better ideas welcome
sleep 0.5
smart channel --show | sed '/rpm-sys/{N;N;d;}' |tee $tmp1

mv /usr/lib/smart/distro.py $tmp2
smart channel --remove-all -y
smart channel --remove rpm-sys -y
sleep 0.5

mkdir -p /tmp/yos-packages

packages=`cat /etc/yis/packages | sort -u | xargs`
[ -z "$packages" ] && packages="ykde-base ykde-standard ymultimedia ydevelopment"

#by default smart ignores distro.py making the default channel config unuseless
#trying to find a sensible approach to 


smart update
smart channel --remove-all -y
sleep 1
smart channel --add $tmp1 -y

#CUSTOMSMARTCHANNEL

sleep 1
echo -e "\n### NOTE: Your software channel configuration ###\n\n"
smart channel --show
sleep 1
smart update
mv $tmp2 /usr/lib/smart/distro.py
echo -e "\n### HINT: The kernel installation won't be able to produce an initrd. That is ok ###\n\n"
smart install kernel -y

kernelvers="$(ls /lib/modules/)"

for m in libifp madwifi ndiswrapper omfs r1000 rt2500 ; do
	smart install kernel-module-$m-${kernelvers} -y 
done

smart install --urls --log-level=debug $packages 2> /tmp/packages  || ( cat /tmp/packages ; exit 1 )
smart channel --remove yoper-3.0-custom -y ||:

/sbin/chkconfig --del samba

smart clean

EOF

[ -n "$BASEURL" ] && sed -i -e 's|#CUSTOMSMARTCHANNEL|smart channel --add yoper-3.0-custom type=apt-rpm baseurl=${BASEURL} components="rocketfuel velocity" -y|g' $destination/tmp/prepare

chmod +x $destination/tmp/prepare

chroot $destination "/tmp/prepare" || func_error "Could not resolve dependencies between package selections.\n`cat $destination/tmp/packages`"

#copy kernel to bootdir of CD
cp -a $destination/boot/vmlinuz* INSTALL.CD/boot/vmlinuz || func_error "Could not copy kernel."
cp -a $destination/boot/System.map* INSTALL.CD/boot/System.map || func_error "Could not copy symbol map."

rm -f $destination/etc/resolv.conf $destination/tmp/prepare

rm -rf $pwd/INSTALL.CD/YOPER
mkdir -p $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel

#check whether there are some rpms locally stored somewhere

mkdir -p $PKGCACHEDIR

#filter existing packages and make sure we copy only the packages we need
#a package gets removed only if it got successfully copied to the ISO

for line in `sort -u $destination/tmp/packages | grep "\.rpm$"` ; do

	if [ -n "$line" ] ; then
		file=`echo $line | awk -F '/' '{print $NF}' | grep "\.rpm$"`

		#file is already present
		if [ -f ${PKGCACHEDIR}/$file ] ; then
			#just copy it and delete it from the file list
			echo "Copying $file ... "
			cp -aL ${PKGCACHEDIR}/$file $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel && sed -i -e "/$file/d" $destination/tmp/packages
		fi

		#if copying felt or was not really done download the file
		if [ ! -f ${PKGCACHEDIR}/$file ] ; then
			echo "Downloading $file ... "
			wget -Nc -P ${PKGCACHEDIR} $line
			cp -aL ${PKGCACHEDIR}/$file $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel && sed -i -e "/$file/d" $destination/tmp/packages
		fi
	fi
done

if [ -z "`grep "\.rpm$" $destination/tmp/packages`" ] ; then
	echo "All packages are present . "
	echo "Creating Indizes ..."

	( cd $pwd/INSTALL.CD/YOPER 
	genbasedir  --flat --bloat `pwd`
	genbasedir  --hashonly `pwd`
	)
	
	echo "Create base Yoper Image ..."
else
	func_error "Some packages could not be found:\n\n`cat $destination/tmp/packages`"
fi

[ -d "$pwd/INSTALL.CD/YOPER/base" ] || func_error "No repository index for installation cd found"

}



func_create_iso(){

clear

echo "Generate checksum file ..."

( cd INSTALL.CD
find . -type f -exec md5sum '{}' \; | sed 's:./:*:' > KNOPPIX/md5sums
cd ..
)

echo "Generate the full CD Image ..."

mkisofs -o ${YVERSION}.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION" INSTALL.CD && echo "ISO has been successfully generated : $pwd/${YVERSION}.iso"

rm -f INSTALL.CD/YOPER/RPMS.rocketfuel/*.rpm
echo "Generate the slim CD Image ..."

mkisofs -o ${YVERSION}-slim.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-`date +%F`" INSTALL.CD && echo "ISO has been successfully generated : $pwd/${YVERSION}-slim.iso"

if [ -d DVD-CACHE ] ; then
rm -fr INSTALL.CD/YOPER
mv DVD-CACHE INSTALL.CD/YOPER
mkisofs -o ${YVERSION}-dvd.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-`date +%F`" INSTALL.CD && echo "ISO has been successfully generated : $pwd/${YVERSION}-dvd.iso"
mv INSTALL.CD/YOPER DVD-CACHE

fi

}




func_all_steps(){

func_prepare_iso || func_error "Could not prepare Yoper Installation CD Image"

dlock=`mktemp`

#let it download, while creating the squashfs image
func_get_packages || func_error "Could not get all packages ..."

echo "Generating Squash Image, which may take a while ..."

yossquashfs=`mktemp`
umount $destination/proc || func_error "Could not unmount /proc ..."
mksquashfs $destination ${yossquashfs} -noappend ; ( rm -rf $destination /var/lib/mach/roots/yoper-3.0-rocketfuel /var/lib/mach/states/yoper-3.0-rocketfuel >/dev/null 2>&1 & )
mv ${yossquashfs} INSTALL.CD/KNOPPIX/KNOPPIX


echo -e "\n\n"
func_create_iso || func_error "Could not create Yoper Installation CD Image"

}

#
#START
#

if [ -z "$1" ] ; then

dialog --backtitle "Yoper ISO Creation" --title "Confirm ISO Creation." --yes-label "Proceed & clear rocketfuel branch" --colors --no-label "Stop, let me sort that first." \
--yesno "\n
\Zb\Z2HINT:\n\n
Choose wisely from where to execute that command! You really should read /usr/share/doc/yis/README before starting ! That should help you understanding what is about to happen. This screen won't tell you all details ! Again please read /usr/share/doc/yis/README before proceeding !\n\n
\Zn\ZBThe following action will be taken:\n
\n
* clean and use the rocketfuel branch to create the basic image. Any data in that buildroot will get deleted!\n
* a lot of data is required and may get downloaded from the internet\n
* I will also do \Z1rm -rf /var/lib/mach/roots/yoper-3.0-rocketfuel ${destination}.\n
\n
Your Yoper ISO ID : ${YVERSION}\n\n
\ZnThe data tree will be:\n\n
top work directory :  \Z1$pwd \n
\Znpackage cache :	      \Z1${PKGCACHEDIR} \n
\Zntemporary image tree: \Z1${destination} \n
\n
\ZnDownload packages from: \Z1${BASEURL} \n
\n
\ZnYou'll find the ISO's here: \Z1$pwd/${YVERSION}.iso \n
Any existing image will get overwritten !\n
\n
\Zn$configfilemsg
\n\n
$cachemsg
" 0 0 

case $? in
	0)
	func_all_steps
	;;
	*)
	func_abort
	;;
esac

else
	[ "$1" == "auto" ] && func_all_steps
fi

func_abort
