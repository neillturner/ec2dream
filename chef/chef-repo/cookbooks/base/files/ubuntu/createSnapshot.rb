#!/usr/bin/ruby
# createSnapshot.rb
# user_data or command parameter on script contains parameters separated by &.
#
# Parameters
#
#     vol=xxxxxxxxx          - volume of snapshots to create 
#
require 'rubygems'
require 'right_aws'
require 'net/http'
require 'date'
# for redhat, centos
#require '/root/settings'
# for ubuntu
require '/home/ubuntu/settings'

def print_message(message)
   puts message+"\n"
   #system('logger '+message+"\n") 
end 

print_message("createSnapshot.rb - Create snapshot for a volume")

# look for command line arguments
args = Array.new
i = 0
ARGV.each do|a|
  args[i]=a
  i+1
end
  

url = 'http://169.254.169.254/latest/meta-data/instance-id'
@instance_id = Net::HTTP.get_response(URI.parse(url)).body
# default amazon access settings
options = {}
options['accesskey'] = Settings.AMAZON_PUBLIC_KEY
options['secretaccesskey'] = Settings.AMAZON_PRIVATE_KEY
options['region'] = Settings.REGION

#
# get parameters from user data if not specified in command line  
#
url_user_data = 'http://169.254.169.254/latest/user-data'
user_data = ""
if args[0]==nil or args[0]==""
   user_data = Net::HTTP.get_response(URI.parse(url_user_data)).body
   if user_data.index("<title>404 - Not Found</title>") != nil
      user_data = ""
      print_message("no user data")
   end 
else
   user_data = args[0]
end 

print_message("UserData: #{user_data}")

if user_data != nil and user_data != ""
   user_data.split('&').each do |param|
      k,v = param.split('=')
      if user_data != nil and user_data != ""
         options[k.downcase] = v
      end   
    end
end 

ec2_vol = options['vol']

if ec2_vol != nil and ec2_vol != ""
   puts "Create Snapshot #{ec2_vol} #{DateTime.now}"
   ec2 = RightAws::Ec2.new(options['accesskey'], options['secretaccesskey'],:endpoint_url => Settings.REGION)
   puts "snapshot #{ec2_vol}"
   vol = ec2.create_snapshot(ec2_vol)
   puts "result #{vol}"
   puts "Snapshot Complete #{ec2_vol} #{DateTime.now}"
end   


