#! /bin/bash

abort(){

killall cp
echo "Copying files failed " 1>&2
RETVAL=1
exit 1

}

touch /var/lock/copy.lock
cp -a /KNOPPIX/* /ramdisk/YIS/root || abort
wait || abort
rm -f /var/lock/copy.lock
