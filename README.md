### EC2Dream - Build and Manage Cloud Servers

[![Gem Version](https://badge.fury.io/rb/ec2dream.svg)](http://badge.fury.io/rb/ec2dream)

For installation see http://ec2dream.blogspot.co.uk/search/label/EC2Dream%20Installation

```
**BREAKING CHANGE** Need to set in the Environment Tab
    field SSL_CERT_FILE to value ca-bundle.crt
**This is now the default**
```

EC2Dream is a graphic user interface that provides a 'single pane of glass' to do agile devops primarily on cloud servers using:
*     Amazon AWS
*     Azure
*     Local and Hosted Servers
*     Google Compute Engine
*     IBM Softlayer
*     Openstack Clouds
*     Vagrant.
*     Test Kitchen (Chef, Puppet, Ansible, Salt).

All using the one client graphical interface and running on Windows, Linux or Mac OSX clients.
(It is written in Ruby using the FXRuby graphics library and Fog cloud services library).

### Features include:
*   Multiple environments based on access key, region.
*   A tree view of your servers.
*   One click SSH, SCP and Remote Desktop access.
*   View Server's System log
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

