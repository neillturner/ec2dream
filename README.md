### EC2Dream - Build and Manage Cloud Servers

[![Gem Version](https://badge.fury.io/rb/ec2dream.svg)](http://badge.fury.io/rb/ec2dream)

For installation see http://ec2dream.blogspot.co.uk/search/label/EC2Dream%20Installation

```
**BREAKING CHANGE** Need to set in the Environment Tab
    field SSL_CERT_FILE to value ca-bundle.crt
**This is now the default**
```

EC2Dream is a visual cloud computing devops product that uses Fog and Ruby supporting:
*     Local and Hosted Servers.
*     Amazon AWS.
*     Openstack Clouds:  Rackspace Cloud Servers and HP Cloud.
*     Google Compute Engine
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
*   Support for Local and Hosted Servers -  Servers running in local virtualized environments like Vagrant, VMWare or Virtual box.
*   Support for ssh tunnelling allow support of servers in Amazon VPC.
*   Support for Amazon AWS including Cloud Formation
*   Support for Test Kitchen to develop and test chef cookbooks, puppet modules, ansible and salt.

### It contains:
*   Ruby and Fog for scripting.
*   Linux servers scripts in ruby.
*   PuTTY for Windows SSH access.
*   winSCP for Windows remote file copying.
*   launchRDP for launching Windows remote desktop.
*   tar.exe for Windows chef repository copying

