### Version 3.7.4 May 2014
enhance test-kitchen support
add test-kitchen puppet support
fix openstack support


### Version 3.7.2 Mar 2014
add test-kitchen support
tidy chef and puppet support.

### Version 3.7.1 Feb 2014
enhancement to chef support.

### Version 3.7.0 Feb 2014
Partial support for google compute engine.
enhancement to puppet support.
added a servers environment.

### Version 3.6.9 Dec 2013
Local Server have a server page.
puppet roles and manifests in amazon aws

### Version 3.6.8  Oct 2013
enhancements to puppet support for roles and hiera.

### Version 3.6.7  Sept 2013
Add support for masterless puppet and ssh tunneling for use with Amazon VPC.

### Version 3.6.6  June 2013
Add support for vagrant. fixes for linux.

### Version 3.6.5  June 2013
fixes mac running chef solo.

### Version 3.6.4  June 2013
fixes for Ruby 187 and mac terminal emulation.


### Version 3.6.3  June 2013
various bug fixes. Cloudwatch graphs for autoscaling groups, elb, ability to run a remote command from the server tab.
autoscaling launch configuration editing now works. performance improves. tags for autoscaling groups.

### Version 3.6.2  May 2013
Extensive changes to support Amazon AWS VPCs.
Improvements to Cloud Formation support by alway saving stack configuration when doing another function.
Added provisioned Iops for creating amazon aws ebs.
List IAM and CDN entities.

### Version 3.6.1 April 2013
fix bugs in create environment.
enhancements to cloudwatch graphs and abilty to configure via json file.

### Version 3.6.0 March 2013
Switch back to standard fog gem as bugs fixed.
Re-architect list processng to be dynamic and extensible.
Create json config for each cloud.
Merge settings and environment tabs.
Move list to first tab.
complete migration from right_aws to fog.
drop right_aws.


### Version 3.5.3 Feb 2013
Correct create Environment

### Version 3.5.2 Feb 2013
Environments in tree
Servers under Security Groups in tree
Launch profiles by server name
Various fixes to bugs


### Version 3.5.1 Feb 2013
Add private ip address
Change tree view of servers to group by security group and use the Amazon tag for the server name
if specified.

### Version 3.5.0 Jan 2013
Full Support for Openstack HP Cloud and Rackspace.
Support for CloudFoundry.
Upgrade of AWS Autoscaling to latest API and fog.
Migration of LoadBalancer to fog,
Start of migration of code from right_aws to the fog ruby cloud services.

### Version 3.4.0 July 2012
Various fixes including correcting monitoring graphs so values should be correct now.
added popups to show password fields.
Chef support extends to windows servers using pocketknife_windows gem.

### Version 3.3.5 June 2012
Fix monitoring graphs, allow windows user to be specified and logon to a server.
Works with Windows Ruby 1.9.3 as restriction on fxruby 1.6.20 removed

### Version 3.3.0 May 2012
Changes to fix bugs on Mac and LInux.

### Version 3.2.5 April 2012
fix bug in unregistering images
Improved support for CloudStack

### Version 3.2 April 2012
Various bug fixes
Partial Support for OpenStack
Support for Local Servers


### Version 3.1 March 2012
Support for Chef
Improved Image Cache
Package as rubygem
Bug fixes


### Version 3.0  Feb 2012
Large rework to upgrade to right_aws 3.0.0
Rework of the scripts.
Works with Ruby 1.9.x
add latest regions
remove remote scripting

### Version 2.3  4 Nov 2010
Added support for auto scaling and RDS Read Replicas


### Version 2.2  4 Oct 2010
Added Tags support for Amazon EC2

### Version 2.1 9 Sept 2010
Corrections for Eucalyptus
Addition of Latest amazon instances

### Version 2.0 1 Sept 2010
Migrate to Right AWS interface 2.0

### Version 1.91 - 12 June 2010
Change install to install dependency right_aws 1.10.0


### Version 1.90 - 19 May 2010
Add new Asia Pacific Region EC2 region
Add US West 1 REgion to RDS
Add support for Load Balancers


### Version 1.87 - 16 Apr 2010
Fix crash when deleting security group
Fix crash when running script when ip adddress changed
In launch allow Disable API termination and Instance Init Shutdown to work
Added eu rds region.
Added support in ebs snapshots to register an image
In launch allow ebs delete on terminate to be modified

### Version 1.86 - 01 Mar 2010
Fixed problem when creating an environment and getting error "undefined method 'copy' for File:Class"

### Version 1.85 - 25 Feb 2010
Improved support for EBS Images
Ability to specify Block Devices for EBS Images
Faster Tooltips
Ability to display image attributes
More info in Image List
Includes latest Version of WinSCP 4.2.5
Improved EBS snapshot support
Create EBS volumes from snapshot list.
Create EBS snapshots from snapshot list.
various bug fixes

### Version 1.80 - 20 Jan 2010
Refactor code so it easier to modify and enhance
various bug fixes
Extra fields on server tab
EBS Image creation and selection.
Start, Stop EBS based servers.
Support for Spot Requests
Add links to cloudexchange.org and cloudmarket.com.

### Version 1.76 - 10 Dec 2009
Fixes for problems in security groups
various minor bug fixes
Fix Right_AWS to pass back RDS errors

### Version 1.75 - 09 Dec 2009
Support for Amazon RDS added
various minor bug fixes


### Version 1.72 - 12 Nov 2009
Improve refresh of tree
Caching of public images
Reduced number of EC2 calls
Faster sorting in EBS, snapshot and image lists.
nicknames used in more screens.
refresh icons immediately.


### Version 1.71 - 04 Nov 2009
Improved Performance
Improved Caching
Reduced number of EC2 calls
Cleaner User Interface
Added Nicknames for snapshots
Powershell script for migrating images


### Version 1.70 - 23 Oct 2009
added Image selection remembers past images.
Added Delete and Deregister Image
Added openbravo install script.
Removed bitnami install scripts.
Updated the install scripts to add a startup script
Updated install for alfresco
Added documentation for faster Windows Ruby Install
Added Nicknames for EBS volumes


### Version 0.99 - 07 Oct 2009
Added install scripts for SugarCRM.

### Version 0.98 - 06 Oct 2009
Correction to Create and Delete Environment
Added file parameter to launch panel.
Added Elastic IP to Server panel.
Elastic IP now used by ssh, remote desktop and scripting.
Added install scripts for Magento.


### Version 0.97 - 30 Sep 2009
Added Migrate Image to windows scripts
moved powershell scripts to Power-ec2dream.
Added monitoring graphs.
Added install scripts for alfresco.
improvements in the gui selection in the other tab.
improvements in linux ssh and scp integration.

### Version 0.95 - 04 Sep 2009
Convert the Other tab to a table for better display
Create environment for eucalyptus from zip file.
Fix errors in windows server settings script.
Added launch profile by image in tree and in table.


### Version 0.94 - 28 Aug 2009
Add missing launchrpd and ruby folders
Fix windows server bundle bug.
Listed Win2K03 snapshots for EU.
Added launch profile by image.
Support for timezone on date/time fields

### Version 0.92 - 14 Aug 2009
Fixed bugs in bundle powershell script and mountebs.cmd server script.
Fixed bug in server scripts for windows initialisation of EBS,
fixed bug in server tree with multiple instances of one security group.
Added scripts for ubuntu servers
Added configurable scripts
Added bitnami install support
Added server page
Added sorting of EBS, snapshots etc.
Added notes page and notes for each server.
Added export function to export in CSV format.
Added link to download latest scripts.
Other minor cosmetic changes

### Version 0.89 - 17 July 2009
Ported to Linux and Mac OS X.
Removed Ruby Windows installer.
Added Keypair support.
Added Image support.
Expanded Image Dialog to select from all images.
Support for Eucalyptus.

### Version 0.87 - 10 July 2009
Fixed incorrect display of EBS volumes and snapshots.
Script for delete old object from S3
Script for deleting old snapshots.
Configurable location of Environment Repository so can have a shared repository.
Remove OK button from popups.
Various bug fixes


### Version 0.85 - 3 July 2009
Added EBS Volumes, Snapshots, IP addresses, System log display.


### Version 0.82 - 26 June 2009
Added powershell support for windows servers.


### Version 0.79 - 19 June 2009
Added ruby scripts and support for linux servers.
