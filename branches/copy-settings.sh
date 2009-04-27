#! /bin/bash

# This script copies the finished settings collected through YIS into the mounted root partition

source /etc/yis/settings

for FILE in `find /ramdisk/YIS/settings` ; do
	DEST=`echo $FILE | sed 's:/ramdisk/YIS/settings::1'`
	cp -a $FILE ${INST_ROOT}/$DEST || RETVAL=1
done

(
cd ${INST_ROOT}/etc/rc.d/rc5.d
rm -f S99YIS-install-packages.sh
cat >> S99YIS-install-packages.sh << "EOF"
#!/bin/sh
/usr/lib/yis/common/install-packages.sh firstboot

EOF
chmod +x S99YIS-install-packages.sh 
)

cat /etc/hosts > ${INST_ROOT}/etc/hosts
touch ${INST_ROOT}/.firstrun


