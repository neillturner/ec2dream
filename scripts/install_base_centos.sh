#!/bin/sh
wget http://s3.amazonaws.com/ServEdge_pub/s3sync/s3sync.tar.gz
# set all .sh file to chmod 700
# upgrade EC2 AIM Tools to latest version
wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm
rpm -Uvh ec2-ami-tools.noarch.rpm
chmod 700 *.sh
chown root *
#
# install ruby from source (already installed on righhtscale images)
#
# cd /usr/local/src
# wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p357.tar.gz
# tar xvzf ruby-1.8.7*.tar.gz
# cd ruby-1.8.7*
# ./configure --enable-shared --enable-pthread
# make
# make install
# cd ext/zlib
# ruby extconf.rb --with-zlib-include=/usr/include --with-zlib-lib=/usr/lib64
# cd ../../
# make
# make install
# cd ext/openssl
# ruby extconf.rb
# make
# make install
# cd ../../
#
# install rubygems 
#
# cd /usr/local/src
# wget http://rubyforge.org/frs/download.php/75711/rubygems-1.8.15.tgz
# tar xvzf rubygem*.tgz
# cd rubygem*
# ruby setup.rb
# gem install rubygems-update
# update_rubygems
#
# Install right_aws the Ruby Amazon AWS Interface
#
# gem install right_aws
#
# install s3sync
#
gzip -d s3sync.tar.gz
tar xvf s3sync.tar
