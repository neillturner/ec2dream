#!/bin/sh
wget http://s3.amazonaws.com/ServEdge_pub/s3sync/s3sync.tar.gz
# set all .sh file to chmod 700
chmod 700 *.sh
chown ubuntu *
# install ruby and s3sync
apt-get update
apt-get -y install ruby-full
apt-get -y install rubygems1.8
gem update
gem install right_aws
gzip -d s3sync.tar.gz
tar xvf s3sync.tar