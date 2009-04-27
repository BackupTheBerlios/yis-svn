#! /bin/bash

cd /KNOPPIX
cat /cdrom/KNOPPIX/md5sums | sed 's:*:/cdrom/:1' | grep "KNOPPIX$" > /var/tmp/md5sums
md5sum --status -c /var/tmp/md5sums &
wait || RETVAL=1 exit 1

