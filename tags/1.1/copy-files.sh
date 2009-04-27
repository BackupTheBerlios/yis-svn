#! /bin/bash

source /etc/yis/settings

abort(){

killall cp
echo "Copying files failed " 1>&2
RETVAL=1
exit 1

}

mkdir -p /var/lock
touch /var/lock/copy.lock
cp -a /KNOPPIX/* ${INST_ROOT} || abort
wait || abort

for replace in `find ${INST_ROOT}/ -name "*.ISO_BAK"` ; do
        new=`echo $replace | sed "s|.ISO_BAK$||1"`
        mv $replace $new || exit 1
done

rm -f /var/lock/copy.lock
