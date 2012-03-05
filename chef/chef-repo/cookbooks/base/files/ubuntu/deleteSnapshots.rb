#!/usr/bin/ruby

# user_data or parameter on script contains one parameter containing values separated by &.
# e.g. 'vol=xxxxxxxx&age=10'
#
# Parameters
#
# vol=xxxx      - volume of snapshots to delete 
# age=999       - age in days of snapshots to delete   

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

print_message("deleteSnapshots.rb - Delete old snapshots for a volume")

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

# set age but if less then 5 set to default of 3-0 days
age = 0 
if options['age'] != nil and options['age'] != ""
   age = Integer(options['age'])
end 
if age < 5 
   age = 30
end   

ec2_vol = options['vol']

if ec2_vol != nil and ec2_vol != ""
   ec2 = RightAws::Ec2.new(options['accesskey'], options['secretaccesskey'], :endpoint_url => Settings.REGION)
   puts "delete snapshots for vol  #{ec2_vol} that are #{age} days old"
   sa  = ec2.describe_snapshots.each do |s|
      aws_volume_id = s[:aws_volume_id]
      if aws_volume_id == ec2_vol then
         d = Time.parse(s[:aws_started_at])
         days_old = Integer((Time.now - d) / (60*60*24))
         if days_old > age then 
            ec2.delete_snapshot(s[:aws_id])
            puts "snapshot #{s[:aws_id]} #{days_old} days old for vol #{s[:aws_volume_id]} deleted"
         else 
            puts "snapshot #{s[:aws_id]} #{days_old} days old for vol #{s[:aws_volume_id]} kept"
         end
      end 
   end            
end
