#!/bin/bash
#
# List Backups in S3
# This sample lists backups in S3 bucket <company>-backup and directory db_backup
#
# for centos 
. /root/settings.sh
# for ubuntu
#. /home/ubuntu/settings.sh

ruby /home/ubuntu/s3sync/s3cmd.rb list <company>-backup:/db_backup  
