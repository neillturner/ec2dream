#!/bin/sh
#
#  Customized pocketknife to run puppet apply on remote node
#
#  Env Variable EC2_PUPPET_REPOSITORY  puppet_repository
#  Env Variable EC2_PUPPET_PARAMETERS  puppet_parameters
#  puppet_push
#  add extra pocketknife_puppet parameters  by changeing the command line and 
#  adding parameters before the $1
#   -t <sudopassword>           specify a sudo password 
#   -d <modules_path>           puppet modulespath separated by colons defaults to modules
#   -n                          don't delete the puppet repo after running puppet 
#   -z                          don't upgrade the server packages before running puppet 
#   -x <xtra options>           add xtra options for puppet apply like --noop 
#
echo "**********************************"
echo "*** Calling pocketknife_puppet ***"
echo "**********************************"
cd $EC2_PUPPET_REPOSITORY
echo pocketknife_puppet $EC2_PUPPET_PARAMETERS  $1
pocketknife_puppet $EC2_PUPPET_PARAMETERS $1


