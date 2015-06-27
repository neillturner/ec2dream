### EC2Dream - Build and Manage Cloud Servers Version 4.0.1 -  June 2015

[![Gem Version](https://badge.fury.io/rb/ec2dream.svg)](http://badge.fury.io/rb/ec2dream)

For installation see http://ec2dream.blogspot.co.uk/search/label/EC2Dream%20Installation

```
**BREAKING CHANGE** Need to add to environment configuration
    SSL_CERT_FILE set to ca-bundle.crt
```

EC2Dream is visual cloud computing admin for the Fog ruby cloud services library and combines Fog, Ruby into an open source devops platform supporting:
*     Local and Hosted Servers.
*     Amazon AWS.
*     Amazon compatible clouds:  Eucalyptus, CloudStack.
*     Openstack Clouds:  Rackspace Cloud Servers and HP Cloud.
*     Google Compute Engine
*     Cloud Foundry.
*     Vagrant.
*     Test Kitchen (Chef, Puppet, Ansible, Salt).

All using the one client graphical interface and running on Windows, Linux or Mac OSX clients.
(It is written in Ruby using the FXRuby graphics library).

### Features include:
*   Multiple environments based on access key, region.
*   A tree view of your servers.
*   One click SSH, SCP and Remote Desktop access.
*   One click Chef testing of cookbooks.
*   One click deregister and delete Image.
*   Launch and terminate Servers
*   View Server's System log
*   Save Launch profile
*   Support for OpenStack HP Cloud and Rackspace including security groups, servers, keypairs, IP addresses, Block Storage volumes and
*   Snapshots.
*   Support for CloudFoundry and ruby dsl.
*   Support for Local and Hosted Servers -  Servers running in local virtualized environments like Vagrant, VMWare or Virtual box.
*   Support for ssh tunnelling allow support of servers in Amazon VPC.
*   Support for Amazon AWS including Cloud Formation, Eucalyptus and openstack
*   Support for Test Kitchen to develop and test chef cookbooks, puppet modules, ansible and salt.

### It contains:
*   Ruby and Fog for scripting.
*   Linux servers scripts in ruby.
*   PuTTY for Windows SSH access.
*   winSCP for Windows remote file copying.
*   launchRDP for launching Windows remote desktop.
*   tar.exe for Windows chef repository copying

