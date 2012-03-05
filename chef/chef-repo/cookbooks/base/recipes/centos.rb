#
# Cookbook Name:: base
# Recipe:: centos
#
# Copyright 2012, EC2Dream.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cookbook_file "/root/backupDirectory.sh" do
  source "backupDirectory.sh"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/bundle.rb" do
  source "bundle.rb"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/cloud_init.rb" do
  source "cloud_init.rb"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/createSnapshot.rb" do
  source "createSnapshot.rb"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/deleteSnapshots.rb" do
  source "deleteSnapshots.rb"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/listBackups.sh" do
  source "listBackups.sh"
  mode 0755
  owner "root"
  group "root"
end
template "/root/settings.rb" do
  source "settings_rb.erb"
  mode 0755
  owner "root"
  group "root"
end
template "/root/settings.sh" do
  source "settings_sh.erb"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file "/root/simple-s3-backup.rb" do
  source "simple-s3-backup.rb"
  mode 0755
  owner "root"
  group "root"
end

cookbook_file "/etc/rc.d/rc.local" do
   source "rc.local"
   mode 0755
   owner "root"
   group "root"
end

gem_package "right_aws" do
  action :install
end

remote_file "/tmp/s3sync.tar.gz" do
 source "http://s3.amazonaws.com/ServEdge_pub/s3sync/s3sync.tar.gz"
 mode "0644"
end

execute "tar" do
 user "root"
 group "root"
 installation_dir = "/root"
 cwd installation_dir
 command "tar zxf /tmp/s3sync.tar.gz"
 creates installation_dir + "/home/ubuntu/s3sync"
 action :run
end

