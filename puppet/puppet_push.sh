#!/bin/sh
#
#  Customized pocketknife to run puppet apply on remote node
#
#  puppet_push puppet_repository puppet_manifest ec2_server_name private_key [ssh_user] [local_port]
#
echo "**********************************"
echo "*** Calling pocketknife_puppet ***"
echo "**********************************"
cd $1
if [ "$5" = "" ]; then
 echo "pocketknife_puppet -ivk $4 -m $2 $3"
 pocketknife_puppet -ivk $4 -m $2 $3
else
 if [ "$6" = "" ]; then
    echo "pocketknife_puppet -ivk $4 -m $2 -s $5 $3"
    pocketknife_puppet -ivk $4 -m $2 -s $5 $3  
 else
    echo "pocketknife_puppet -ivk $4 -m $2 -s $5 $3"
    pocketknife_puppet -ivk $4 -m $2 -s $5 -l $6 $3
 fi 
fi  

