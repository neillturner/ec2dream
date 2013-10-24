#!/bin/sh
#
#  Customized pocketknife to run puppet apply on remote node
#
#  Env Variable EC2_PUPPET_REPOSITORY  puppet_repository
#  Env Variable EC2_PUPPET_PARAMETERS  puppet_parameters
#  puppet_push
#
echo "**********************************"
echo "*** Calling pocketknife_puppet ***"
echo "**********************************"
cd $EC2_PUPPET_REPOSITORY
echo pocketknife_puppet $EC2_PUPPET_PARAMETERS
pocketknife_puppet $EC2_PUPPET_PARAMETERS


