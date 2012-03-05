#
# Cookbook Name:: base_hosted
# Recipe:: ubuntu
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

template "/etc/chef/client.rb" do
  source "client_rb.erb"
  mode 0755
  owner "ubuntu"
  group "ubuntu"
end

cookbook_file "/etc/chef/#{node[:base_hosted][:organization]}-validator.pem" do
  source "#{node[:base_hosted][:organization]}-validator.pem"
  mode 0755
  owner "ubuntu"
  group "ubuntu"
end 




