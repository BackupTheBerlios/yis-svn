#!/bin/bash

#This script is GPL and part of the yoper-commandline-installer

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n" 1>&2
	exit 1
fi

winparts1=`fdisk -l 2>/dev/null| grep '[F,f][A,a][T,t]32' | cut -c6-10`
winparts2=`fdisk -l 2>/dev/null| grep '[N,n][T,t][F,f][S,s]' | cut -c6-10`

#
#lilo.conf generation
#

root_dev="`cat $TMP/root_partition_choice`" || abort_on_error "No root partition defined"
boot_dev="`echo $root_dev | cut -c1-8`"

mkdir -p ${INST_ROOT}/{etc,boot/grub}

cat /etc/yis/lilo.conf.template | \
# add path where lilo gets installed
sed "s:BOOT_DEV:"${boot_dev}":g" | \
# Change Yoper Version
sed "s:YVERSION:"$YVERSION":g" | \
# Change root partition in boot cmdline
sed "s:ROOT_DEV:$root_dev:g" | \
# Change Kernel Version
sed "s:KVERSION:"$KVERSION":g" > $INST_ROOT/etc/lilo.conf

wincount=1

for part in $winparts1  ; do

wincount=$[wincount+1]
echo "other = /dev/${part}
label = Windows_fat_${wincount}

" >> $INST_ROOT/etc/lilo.conf

done

for part in $winparts2  ; do

wincount=$[wincount+1]
echo "other = /dev/${part}
label = Windows_ntfs_${wincount}

" >> $INST_ROOT/etc/lilo.conf

done

#
# grub.conf generation
# 



convert_alpha_num(){

[ -z "$1" ] && abort_on_error

root_num=`echo $1 | tr  abcdefghij 0123456789`

[ "$1" == "k" ] && root_num=10
[ "$1" == "l" ] && root_num=11
[ "$1" == "m" ] && root_num=12
[ "$1" == "n" ] && root_num=13
[ "$1" == "o" ] && root_num=14
[ "$1" == "p" ] && root_num=15
[ "$1" == "q" ] && root_num=16
[ "$1" == "r" ] && root_num=17
[ "$1" == "s" ] && root_num=18
[ "$1" == "r" ] && root_num=19

}


root_num="`echo $root_dev | cut -c8-8`"
convert_alpha_num $root_num
root_hd="hd${root_num}"
root_part="`echo $root_dev | cut -c9-9`"
root_part=$[root_part-1]

[ "$root_part" -lt "0" ] && root_part=0

# make sure everything is written as supposed
if [ -d /usr/share/grub/i386-pc ] ; then
	mkdir -p $INST_ROOT/boot/grub
	cp -a /usr/share/grub/i386-pc/* $INST_ROOT/boot/grub
else
	abort_on_error "Grub stage files not found, grub not installed ?"
fi

cat /etc/yis/grub.conf.template | \
# add path where grub gets installed
sed "s:BOOT_DEV:${boot_dev}:g" | \
# Change root partition in boot cmdline
sed "s:ROOT_DEV:${root_dev}:g" | \
# Change Kernel Version
sed "s:KVERSION:"$KVERSION":g" | \
# Change Yoper Version
sed "s:VERSION:"${VERSION}":g" | \
#change yoper partition details
sed "s:ROOTHD:"${root_hd}":g" | sed "s:ROOTPART:"${root_part}":g" \
> $INST_ROOT/boot/grub/grub.conf

echo "root (${root_hd},${root_part})
setup (hd0)
" >  $INST_ROOT/etc/grub-install.conf
cp -a $INST_ROOT/etc/grub-install.conf /etc

#
# Plain C&P from SaxenOS
#

#Adding possible Windows NT/2k/XP entries
for x in $winparts2; do
	cnt2=$((`echo $w | cut -c4-5`-1))
	[ "$cnt2" -lt "0" ] && cnt2=0
	echo "title Windows NT/2k/XP on $x" >> $INST_ROOT/boot/grub/grub.conf
	echo "rootnoverify (hd0,$cnt2)" >> $INST_ROOT/boot/grub/grub.conf
	echo "chainloader +1" >> $INST_ROOT/boot/grub/grub.conf
	echo " " >> $INST_ROOT/boot/grub/grub.conf
done

#Adding possible Windows 95/98 entries
for w in $winparts1; do
	cnt1=$((`echo $w | cut -c4-5`-1))
	[ "$cnt1" -lt "0" ] && cnt1=0
	echo "title Windows 95/98/ME on $w" >> $INST_ROOT/boot/grub/grub.conf
	echo "rootnoverify (hd0,$cnt1)" >> $INST_ROOT/boot/grub/grub.conf
	echo "chainloader +1" >> $INST_ROOT/boot/grub/grub.conf
	echo " " >> $INST_ROOT/boot/grub/grub.conf
done

( cd $INST_ROOT/boot/grub && rm -f menu.lst && cp -a grub.conf menu.lst )

#cp $INST_ROOT/boot/grub/grub.conf /boot/grub || exit 1

