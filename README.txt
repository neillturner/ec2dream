Fogviz - Build and Manage EC2 Servers Version 3.6.6 -  June 2013 
-----------------------------------------------------------------

Fogviz is visual cloud computing admin for the Fog ruby cloud services library and combines Fog, Ruby, Chef and Git into an open source devops platform supporting:
      Amazon AWS.
      Amazon compatible clouds:  Eucalyptus, CloudStack.
      Openstack Clouds:  Rackspace Cloud Servers and HP Cloud.
      Cloud Foundry and even Local Servers and Vagrant.

It uses Chef Solo to install software and applications via "one click" and Hosted Chef particularly for production environments.

All using the one client graphical interface and running on Windows, Linux or Mac OSX clients.
(It is written in Ruby using the FXRuby graphics library). 

Features include:
   Multiple environments based on access key, region.
   A tree view of your servers.
   One click SSH, SCP and Remote Desktop access.
   One click Chef testing of cookbooks.
   One click deregister and delete Image.
   Launch and terminate Servers
   View Server's System log
   Save Launch profile
   Support for OpenStack HP Cloud and Rackspace including security groups, servers, keypairs, IP addresses, Block Storage volumes and
   Snapshots.  
   Support for CloudFoundry
   Support for Local Servers -  Servers running in local virtualized environments like VMWare Player are supported and the Chef 
   integration will work. Ideal for testing chef cookbooks. 
   Support for Chef - one click testing of chef cookbooks via chef solo , support for Hosted Chef. Can pass chef runlist in userdata at startup
   Support for Amazon AWS, Eucalyptus and Cloudstack

It contains:
   Chef, Ruby and Fog for scripting.
   Linux servers scripts in ruby.
   PuTTY for Windows SSH access.
   winSCP for Windows remote file copying. 
   launchRDP for launching Windows remote desktop.
   tar.exe for Windows chef repository copying

