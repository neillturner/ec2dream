#!/bin/bash
#
# Backup Directory
# in this example the jboss log directory is backed up
#  /mnt/data01/jboss/server/all/log/
# To do this every x mins add to crontab
#
# for centos
#. /root/settings.sh
# for ubuntu
. /home/ubuntu/settings.sh
export LOCAL_HOSTNAME=<servername>
echo "host " $LOCAL_HOSTNAME
echo date 
# set name of S3 bucket
echo "backup log folder to S3 bucket "$S3_PREFIX"-backup:"$LOCAL_HOSTNAME"-log"
ruby /home/ubuntu/s3sync/s3sync.rb  -r --delete  /mnt/data01/jboss/server/all/log/  $S3_PREFIX-backup:/$LOCAL_HOSTNAME-log
