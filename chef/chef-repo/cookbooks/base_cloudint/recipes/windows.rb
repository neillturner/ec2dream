#
# Cookbook Name:: base
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

cookbook_file "c:/users/administrator/cloud_init.rb" do
  source "cloud_init.rb"
end

template 'c:/users/administrator/settings.rb' do
  source 'settings_rb.erb'
end

template 'c:/users/administrator/create_sched_task.cmd' do
  source 'create_sched_task_cmd.erb'
end

gem_package "right_aws" do
  action :install
end

# create a scheduled the task
execute "create scheduled task to run cloud_init at startup" do
  command 'c:/users/administrator/create_sched_task.cmd'
end  








