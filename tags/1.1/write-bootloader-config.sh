#!/bin/bash

#This script is GPL and part of the yoper-commandline-installer

if [ -f /etc/yis/settings ] ; then
	source /etc/yis/settings
else
	echo -e "$(color ltgreen black)Installation Media corrupted, aborting installation ! \n" 1>&2
	exit 1
fi

#
#lilo.conf generation
#

root_dev="`cat $TMP/root_partition_choice`" || abort_on_error "No root partition defined"
boot_dev="`echo $root_dev | cut -c1-8`"

cat /etc/yis/lilo.conf.template | \
# add path where lilo gets installed
sed "s:BOOT_DEV:"${boot_dev}":g" | \
# Change Yoper Version
sed "s:YVERSION:"$YVERSION":g" | \
# Change root partition in boot cmdline
sed "s:ROOT_DEV:$root_dev:g" | \
# Change Kernel Version
sed "s:KVERSION:"$KVERSION":g" > $INST_ROOT/etc/lilo.conf


#
# grub.conf generation
# 


convert_alpha_num(){

[ -z "$1" ] && abort_on_error

[ "$1" == "a" ] && root_num=0
[ "$1" == "b" ] && root_num=1
[ "$1" == "c" ] && root_num=2
[ "$1" == "d" ] && root_num=3
[ "$1" == "e" ] && root_num=4
[ "$1" == "f" ] && root_num=5
[ "$1" == "g" ] && root_num=6
[ "$1" == "h" ] && root_num=7

}


root_num="`echo $root_dev | cut -c8-8`"
convert_alpha_num $root_num
root_hd="`echo $root_dev | cut -c6-7`${root_num}"
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

#
# Plain C&P from SaxenOS
#

#Adding possible Windows NT/2k/XP entries
winparts2=`fdisk -l | grep '[N,n][T,t][F,f][S,s]' | cut -c6-10`
for x in $winparts2; do
	cnt2=$((`echo $w | cut -c4-5`-1))
	echo "title Windows NT/2k/XP on $x" >> $INST_ROOT/boot/grub/grub.conf
	echo "root (hd0,$cnt2)" >> $INST_ROOT/boot/grub/grub.conf
	echo "chainloader +1" >> $INST_ROOT/boot/grub/grub.conf
	echo "makeactive" >> $INST_ROOT/boot/grub/grub.conf
	echo " " >> $INST_ROOT/boot/grub/grub.conf
done

#Adding possible Windows 95/98 entries
winparts1=`fdisk -l | grep '[F,f][A,a][T,t]32' | cut -c6-10`
for w in $winparts1; do
	cnt1=$((`echo $w | cut -c4-5`-1))
	echo "title Windows 95/98/ME on $w" >> $INST_ROOT/boot/grub/grub.conf
	echo "root (hd0,$cnt1)" >> $INST_ROOT/boot/grub/grub.conf
	echo "chainloader +1" >> $INST_ROOT/boot/grub/grub.conf
	echo "makeactive" >> $INST_ROOT/boot/grub/grub.conf
	echo " " >> $INST_ROOT/boot/grub/grub.conf
done

( cd $INST_ROOT/boot/grub && rm -f menu.lst && ln -sf grub.conf menu.lst )
