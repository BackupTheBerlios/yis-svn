#!/bin/bash


func_abort(){

set +x

if [ -n $destination ] ; then
	umount $destination/proc >/dev/null 2>&1 ||:
	rm -f $installcdfiles $yossquashfs 
	#split that to avoid overloading argumentlist
	rm -rf $destination > /dev/null 2>&1 &
	[ -n "${FULLBRANCH}" ] && umount /var/lib/mach/roots/${FULLBRANCH}/proc 2>/dev/null 
	[ -n "${FULLBRANCH}" ] && rm -rf /var/lib/mach/roots/${FULLBRANCH} /var/lib/mach/states/${FULLBRANCH} > /dev/null 2>&1 &
fi

exit 0

}

func_missing(){

echo -e "\nPrerequisite not met:\n${1}\n" 1>&2

func_abort

}

func_error(){

echo -e "\nError occured:\n${1}\n" 1>&2

func_abort

}

configfile=
pwd=`pwd`

# if we want to build auto cd's we don't read local config

if [ "$1" != "auto" ] ; then

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

# create all variables here to include them in the confirmation screen
[ -z "$PKGCACHEDIR" ] && PKGCACHEDIR=$pwd/pkg-cache
[ -z "$YVERSION" ] && YVERSION=YOS-`date +%Y-%j`
[ -z "$ISOTYPE" ] && ISOTYPE=all

#determine the distro, release and branch to use 

[ -z "$DISTRO" ] && DISTRO=yoper
[ -z "$RELEASE" ] && RELEASE=3.1
[ -z "$BRANCH" ] && BRANCH=rocketfuel

[ -z "$BASEURL" ] && BASEURL=http://development.yoper.com/pub/yoper/pkg

[ -z "$FULLBRANCH" ] && FULLBRANCH=${DISTRO}-${BRANCH}

[ -z "$BASEPKGS" ] && BASEPKGS="Linux-PAM MAKEDEV aalib acpid dash bash beecrypt bzip2 chkconfig color compat-libstdc.so.5 console-tools coreutils cpio cracklib curl cyrus-sasl db4 device-mapper dhcp-client dialog diffutils disktype e2fsprogs eject elfutils ethtool file findutils fuse gawk glibc gmp grep groff grub gzip hdparm hwdata hwsetup infozip iproute iptables kbd kudzu less lilo logrotate lua lzo man mc module-init-tools nano ncurses net-tools newt ntfs-3g ntfsprogs openssh openssl parted patch pciutils pcre powernowd prelink procinfo procps progsreiserfs psmisc pth python python-xml readahead readline rebuildfstab resmgr rpm rpm-python sed shadow sharutils smartpm sqlite sudo sysfsutils sysvinit tar texinfo udev unzip usbutils usermode utempter util-linux-ng wget wireless-tools words xfsprogs yaird yoper-rpm-settings yoperbase yoperinitscripts yopermaintain zlib sshfs-fuse pcmcia-utils wpa_supplicant yoper-kde-settings fcron reiserfsprogs ntp-date reiser4progs mirrorwatch rp-pppoe oss-gpl pam_userlist tz-select"

[ "$UID" = "0" ] || func_missing "you are not root"

destination=$destination

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

if [ ! -d "$pwd/INSTALL.CD" ] ; then
	echo "Need to download archive for CD skeleton ... "
	installcdfiles=`mktemp`
	curl http://development.yoper.com/pub/devel/source-cache/installcd-files-2008-08-22.tar.bz2 > $installcdfiles
	[ "`md5sum $installcdfiles | awk '{print $1}'`" != "ea1e8da59efda059ce5699878e5380ae" ] && \
	func_missing "The md5sum of the install cd skeleton archive does not match !"
	tar xf $installcdfiles -C $pwd && rm -f $installcdfiles
fi

if [ ! -d "$pwd/YIS" ] ; then
        echo "No Local YIS Copy found !"
	echo "You are supposed to have a local file tree of yis in $pwd/YIS !"
	exit 1
fi


[ -n "`ls $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel/*.rpm`" ] && cachemsg="Warning: You have some packages left in:\n${pwd}/INSTALL.CD/YOPER \nThose files will be DELETED!"


func_create_basic_image(){

clear 
echo "Cleaning out temporary data ..."

rm -f $pwd/INSTALL.CD/YOPER/RPMS.rocketfuel/*.rpm $pwd/INSTALL.CD/YOPER/YOPER $pwd/INSTALL.CD/boot/vmlinuz $pwd/INSTALL.CD/boot/System.map

[ -n "${FULLBRANCH}" ] && rm -rf /var/lib/mach/roots/${FULLBRANCH} /var/lib/mach/states/${FULLBRANCH} $destination > /dev/null 2>&1 && mach -r ${FULLBRANCH} -f unlock

sleep 1

[ -n "${FULLBRANCH}" ] &&  rm -rf /var/lib/mach/roots/${FULLBRANCH} /var/lib/mach/states/${FULLBRANCH} $destination > /dev/null 2>&1 && mach -r ${FULLBRANCH} clean >/dev/null 2>&1

sleep 1	

mach -r ${FULLBRANCH} clean >/dev/null 2>&1 || func_error "Could not clean out mach environment"
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

ln -s $destination /var/lib/mach/roots/${FULLBRANCH}

echo "Installing Minimal Yoper Environment ..."

mach -d -r ${FULLBRANCH} setup base >/dev/null || func_error "Could not setup mach base"

cat /etc/resolv.conf > $destination/etc/resolv.conf

chroot $destination /usr/sbin/create-cracklib-dict /usr/share/dict/words || func_error "Could not generate password database"

mach -d -r ${FULLBRANCH} apt-get install rpm yoper-rpm-settings >/dev/null
mach -d -r ${FULLBRANCH} apt-get install smartpm >/dev/null

queue=""

for p in $BASEPKGS yoperinitscripts ; do
	queue="$queue $p"

	if [ "`echo $queue | wc -w`" -gt "4" ] ; then
		echo -e "\tInstalling : $queue"
		mach -d -r ${FULLBRANCH} apt-get install $queue >/dev/null
		queue=""
	fi

done

echo -e "\tVerifying package list ..."

mach -d -r ${FULLBRANCH} apt-get install $BASEPKGS >/dev/null

tmppkglist=`mktemp`

rpm --root=$destination -qa --qf "%{name} \n" | sort -u > $tmppkglist

for p in ${BASEPKGS} ; do
	/bin/true
	[ -n "`grep $p $tmppkglist 2>/dev/null`" ] || func_error "Could not find mandatory package $p in base system"
done

rm -f $tmppkglist

chmod 4711 $destination/usr/bin/sudo

if [ -d $pwd/YIS ] ; then
       	cp -aLv $pwd/YIS/* $destination
fi

if [ -f $destination/etc/inittab ] ; then
	cp -aL --suffix .ISO_BAK $destination/etc/yis/inittab.cd $destination/etc/inittab || func_error "Could not replace init configuration file"
else
	func_error "No regular init config file ( /etc/inittab ) found. "
fi

#
# Install Kernel and std modules
#

set -x
kernelvers="$(mach -r ${FULLBRANCH} apt-cache search kernel-2.6 |grep ^kernel-2.6 | sort -u | grep -v smp | \
tail -n 1 | awk '{print $1}' | sed 's|kernel-||g')"

mach -r ${FULLBRANCH} apt-get install kernel-$kernelvers kernel-$kernelvers-smp || func_error "Could not install the kernel $kernelvers and required modules"

#packages that are not in BASEPKGS because they would pull in the kernel
mach -r ${FULLBRANCH} apt-get install ndiswrapper ndiswrapper_bcmwl5 zd1211 -y

for m in oss aufs libifp madwifi ndiswrapper omfs rt2500 ; do
	echo install kernel-module-$m-${kernelvers} 
	mach -r ${FULLBRANCH} apt-get install kernel-module-$m-${kernelvers} kernel-module-$m-${kernelvers}-smp -y 
done

#copy kernel to bootdir of CD
cp -a $destination/boot/vmlinuz-${kernelvers} INSTALL.CD/boot/vmlinuz || func_error "Could not copy kernel."
cp -a $destination/boot/System.map-${kernelvers} INSTALL.CD/boot/System.map || func_error "Could not copy symbol map."

#for convenience 
find $destination/usr/lib/yis -type f -exec chmod +x '{}' \;

#add all sort of storage modules to the initrd of the installation cd ( could we do that for yoper, too ?)

tmpmount=`mktemp -d`

rm INSTALL.CD/boot/oldminiroot* INSTALL.CD/boot/newminiroot*
cp INSTALL.CD/boot/miniroot.gz INSTALL.CD/boot/oldminiroot.gz && gunzip INSTALL.CD/boot/oldminiroot.gz && \
cp INSTALL.CD/boot/oldminiroot INSTALL.CD/boot/newminiroot
mount INSTALL.CD/boot/newminiroot $tmpmount -o loop && [ -n "$tmpmount" ] && rm -rf $tmpmount/modules && mkdir -p $tmpmount/modules

[ -d $tmpmount/modules ] && \ 
for module in ata/pata_it8213.ko ata/pata_opti.ko ata/pata_optidma.ko ata/pata_pcmcia.ko ata/pata_pdc202xx_old.ko ata/pata_radisys.ko ata/pata_serverworks.ko ata/pata_winbond.ko ata/sata_inic162x.ko usb/host/ehci-hcd.ko usb/host/isp116x-hcd.ko usb/host/ohci-hcd.ko usb/host/uhci-hcd.ko usb/storage/libusual.ko usb/storage/usb-storage.ko usb/core/usbcore.ko ; do 

	srcmod="$destination/lib/modules/${kernelvers}/kernel/drivers/$module"
	tgtmod="$tmpmount/modules/$module"

	if [ -f "$srcmod" ] ; then

		echo "Adding module to installation initrd: $module"
		#make sure we have all required subdirs		
		mkdir -p $tgtmod && rmdir $tgtmod
		cp -a $srcmod $tgtmod
	else
		echo "Could not find : $module"
	fi
done

#for module in extra/sqlzma.ko extra/unlzma.ko kernel/fs/squashfs/squashfs.ko ; do 
for module in kernel/fs/squashfs/squashfs.ko ; do 

	srcmod="$destination/lib/modules/${kernelvers}/$module"
	tgtmod="$tmpmount/modules/$module"

	if [ -f "$srcmod" ] ; then

		echo "Adding module to installation initrd: $module"
		#make sure we have all required subdirs		
		mkdir -p $tgtmod && rmdir $tgtmod
		cp -a $srcmod $tgtmod
	else
		func_error "Could not install essential prereq : $module"
	fi
done

umount $tmpmount && gzip INSTALL.CD/boot/newminiroot && \
mv INSTALL.CD/boot/newminiroot.gz INSTALL.CD/boot/miniroot.gz && \
mv INSTALL.CD/boot/oldminiroot .

#install release notes
tmp=`mktemp -t` 
wget -O $tmp http://development.yoper.com/pub/devel/source-cache/release-notes-${RELEASE}.tar.bz2
mkdir -p $destination/usr/share/yoper
tar xf $tmp -C $destination/usr/share/yoper
rm -f $tmp

return 0

}

# create squash image for any ISO

func_create_squash_image(){

umount $destination/proc 

echo "Create Squash Image ..."

#some cleanups
if [ -n "$destination" ] ; then
	find $destination/ -name '*.rpm*' -or -name '*~' -exec rm -f '{}' \;
	rm -f $destination/etc/dhcp/resolv.conf rm -f $destination/etc/resolv.conf
fi

isosize=`du -s $destination/ |awk '{print $1}'`
isosize=$[isosize*105/100]

sed -i -e  '/FINSIZE/d' $destination/etc/yis/settings
echo "export FINSIZE=$isosize" >> $destination/etc/yis/settings

yossquashfs=`mktemp -p $pwd`
#mksquashfs $destination ${yossquashfs} -noappend -no-progress || func_error "Could not generate squash image"
touch $destination/.firstrun

set -x
mount --bind /proc $destination/proc
chroot $destination /etc/init.d/crond stop
chroot $destination /bin/killall prelink
umount $destination/proc

mksquashfs $destination ${yossquashfs} -noappend -no-progress -nolzma || func_error "Could not generate squash image"
mkdir -p INSTALL.CD/YOPER
mv ${yossquashfs} INSTALL.CD/YOPER/YOPER

}

#install a pkg set based on /etc/yis/packages.info

func_install_pkgset(){


setno=$1

#arg has to be a number matching the wanted package set in packages.info

setname=$(awk -v pat="SET${setno}_NAME" -F'"' '$1 ~ pat {print $2}' $pwd/YIS/etc/yis/packages.info 2>/dev/null)
setchan=$(awk -v pat="SET${setno}_COMP" -F'"' '$1 ~ pat {print $2}' $pwd/YIS/etc/yis/packages.info 2>/dev/null)

[ -n "$setchan" ] || setchan=rocketfuel

if [ -n "$setno" -a -n "$setname" ] ; then

echo installing pkgset $setname ...

#clean it all out

func_create_basic_image || func_error "could not create basic image"

cat /etc/resolv.conf > $destination/etc/resolv.conf
rm -f $destination/tmp/prepare

echo "#!/bin/bash -x
setno=$setno
BASEURL=$BASEURL
FULLBRANCH=$FULLBRANCH
COMPONENTS=\"$setchan\"

" > $destination/tmp/prepare

cat >> $destination/tmp/prepare <<"EOF"

mount -t proc proc /proc

[ -f /etc/yis/settings ] && . /etc/yis/settings

[ -f /etc/yis/packages.info ] && . /etc/yis/packages.info

plist=$(awk -v pat="SET${setno}_LIST" -F'"' '$1 ~ pat {print $2}' /etc/yis/packages.info)

if [ -n "$plist" ] ; then
	
	for file in /etc/smart/channels/*.channel ; do mv $file ${file}.ISO_BAK ; done
	
	smart channel --disable yoper-3.0 -y
	smart channel --disable yoper-3.1 -y
	smart channel --disable yoper-dev -y

tmpchan=`mktemp -t`

echo "

[$FULLBRANCH]
type = apt-rpm
baseurl=$BASEURL
components = $COMPONENTS
" > $tmpchan

	LANG=C && echo y | smart channel --add $tmpchan
	LANG=C && echo y | smart-update

	smart install $plist -y && touch /tmp/success

	smart fix -y
	smart clean 

	for file in /etc/smart/channels/*.ISO_BAK ; do
		oldfile=$(echo $file | sed 's|.ISO_BAK$||g')
		mv $file $oldfile
	done

	rm -f /var/lib/smart/cache /var/lib/smart/channels/* $tmpchan

fi

smart update

umount /proc

EOF

chmod +x $destination/tmp/prepare

chroot $destination "/tmp/prepare" || func_error "Could not resolve dependencies between package selections.\n`cat $destination/tmp/*packages`"

[ -f $destination/tmp/success ] || func_error "Some error during package setup occurred"

rm -f $destination/etc/resolv.conf $destination/tmp/prepare $destination/tmp/success

else
	func_error "Package set no : $setno not found"
fi

}


func_create_slim_iso(){

if [ "$ISOTYPE" = "slim" -o "$ISOTYPE" = "all" ] ; then

echo "Generate the slim CD ..."

#slim iso is always first
func_create_basic_image

rm -fr INSTALL.CD/YOPER/*

sed -i -e '/ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=slim" >> $destination/etc/yis/settings

func_create_squash_image

echo "Create Slim CD ISO Image ..."

mkisofs -o ${YVERSION}-slim.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-slim" INSTALL.CD && echo "Slim CD ISO has been successfully generated : $pwd/${YVERSION}-slim.iso"

else

echo "Skipping slim CD Image ..."

fi

}


func_create_kde4_iso(){

func_install_pkgset 10

sed -i -e '/^ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=kde4" >> $destination/etc/yis/settings
echo KDE4 > $destination/etc/sysconfig/desktop

func_create_squash_image

echo "Create KDE4 iso ..."

mkisofs -o ${YVERSION}-kde4.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-kde4" INSTALL.CD && echo "KDE4 CD ISO has been successfully generated : $pwd/${YVERSION}-kde4.iso"

}


func_create_live_iso(){

func_install_pkgset 09

sed -i -e '/^ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=live" >> $destination/etc/yis/settings

func_create_squash_image

echo "Create live iso ..."

mkisofs -o ${YVERSION}-live.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-live" INSTALL.CD && echo "live CD ISO has been successfully generated : $pwd/${YVERSION}-live.iso"

}

func_create_e17_iso(){

func_install_pkgset 11

sed -i -e '/^ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=E17" >> $destination/etc/yis/settings
echo e17 > $destination/etc/sysconfig/desktop

func_create_squash_image

echo "Create e17 iso ..."

mkisofs -o ${YVERSION}-e17.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-e17" INSTALL.CD && echo "live CD ISO has been successfully generated : $pwd/${YVERSION}-e17.iso"

}


func_create_dev_iso(){

#personal helper cd to get office machine's into distcc mode
#just pop into your drive and have another distcc client

if [ "$ISOTYPE" = "distcc" ] ; then

func_create_basic_image

rm -fr INSTALL.CD/YOPER/*

mach -r ${FULLBRANCH} apt-get install kernel-meta-devel make distcc

sed -i -e  '/ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=dev" >> $destination/etc/yis/settings

func_create_squash_image

echo "Create distcc client Image ..."

mkisofs -o ${YVERSION}-distcc.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-distcc" INSTALL.CD && echo "DistCC Client ISO has been successfully generated : $pwd/${YVERSION}-distcc.iso"

fi

}

func_create_dvd_iso(){


if [ -d DVD-CACHE ] && [ "$ISOTYPE" = "dvd" -o "$ISOTYPE" = "all" ] ; then

echo "Generate the full DVD Image ..."

rm -fr INSTALL.CD/YOPER
mv DVD-CACHE INSTALL.CD/YOPER

sed -i -e '/ISOTYPE/d' $destination/etc/yis/settings
echo "export ISOTYPE=dvd" >> $destination/etc/yis/settings

#we come from the live cd so actually it should be all installed
mach -r ${FULLBRANCH} apt-get install ykde-standard -y || func_error "Could not install standard packages for DVD"

mkisofs -o ${YVERSION}-dvd.iso -R -l -D -b boot/grub/iso9660_stage1_5 -no-emul-boot -boot-load-size 4 \
-boot-info-table -V "$YVERSION-DVD" INSTALL.CD && echo "DVD ISO Image has been successfully generated : $pwd/${YVERSION}-dvd.iso"
mv INSTALL.CD/YOPER DVD-CACHE

fi

}


func_build_isos(){

if [ "$ISOTYPE" == "all" -o -z "$ISOTYPE" ] ; then
	func_create_slim_iso || func_error "Could not create Slim CD Image"
	func_create_e17_iso  || func_error "could not create e17 cd image"
	func_create_live_iso || func_error "could not create live cd image"
	func_create_kde4_iso || func_error "could not create kde4 cd image"
else
	case $ISOTYPE in
		slim|e17|live|kde4)
			func_create_${ISOTYPE}_iso || func_error "could not create kde4 cd image"
			;;
	esac
fi

#func_create_dvd_iso || func_error "Could not create DVD Image"
#func_create_dev_iso || func_error "Could not create distcc Image"

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
* I will also do \Z1rm -rf /var/lib/mach/roots/${FULLBRANCH} ${destination}.\n
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
	func_build_isos
	;;
	*)
	func_abort
	;;
esac

else
	[ "$1" = "auto" ] && func_build_isos
fi

func_abort
