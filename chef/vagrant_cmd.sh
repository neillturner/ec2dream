#!/bin/sh
#
#  vagrant up command 
#
#  vagant_up <directory> <command>
#  
#  <directory> is directory of Vagrantfile
#  <command> is command for vagrant i.e. up or destroy
#
echo "***************************"
echo "*** Calling vagrant     ***"
echo "***************************"

export VAGRANT_LOG=debug
cd $1
vagrant $2