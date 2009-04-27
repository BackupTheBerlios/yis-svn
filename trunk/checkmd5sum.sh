#! /bin/bash

cd /YOPER
cat /cdrom/YOPER/md5sums | sed 's:*:/cdrom/:1' | grep "YOPER$" > /var/tmp/md5sums
md5sum --status -c /var/tmp/md5sums &
wait || RETVAL=1 exit 1

