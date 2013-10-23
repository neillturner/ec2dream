#!/bin/sh
#
#  Customized pocketknife to run chef-solo on remote node
#
#  chef_push chef_repository chef_node ec2_server_name private_key [ssh_user]
#  To set a chef version to install add -j <version> to the end of the pocketknife command where <version> is 11.4.2 for example
#
echo "***************************"
echo "*** Calling pocketknife ***"
echo "***************************"
rm  $1/nodes/$3.json 
cp $1/nodes/$2.json $1/nodes/$3.json 
cd $1
if [ "$5" = "" ]; then
 echo "pocketknife -ivk $4 $3"
 pocketknife -ivk $4 $3
else
 if [ "$6" = "" ]; then
    echo "pocketknife -ivk $4 -s $5 $3"
    pocketknife -ivk $4 -s $5 $3 
 else
    echo "pocketknife -ivk $4 -s $5 -l $6 $3"
    pocketknife -ivk $4 -s $5 -l $6 $3 
 fi 
fi  
rm  $1/nodes/$3.json 