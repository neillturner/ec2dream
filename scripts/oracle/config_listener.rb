#!/usr/bin/ruby
#
# Script to configure the oracle listener file. 
#
# takes a parameter that is the oracle_home  
#
# Run via 
#     ruby config_listener.rb <oracle_home>
#
# For ubuntu add this script to etc/rc.local to automate the attach of EBS.
#       ruby /home/ubuntu/config_listener.rb oraclehome=<oracle_home>
# For redhat/centos add this script to etc/rc.local to automate the attach of EBS.
#       ruby /root/config_listener.rb <oracle_home>
#
# or you can set oraclehome in the userdata 
#       oraclehome=<oracle_home>&anotherparm=anothervar       
#
#
#
require 'rubygems'
require 'right_aws'
require 'net/http'
require 'socket'
# for redhat, centos
require '/root/settings'
@sudo = ""
# for ubuntu
#require '/home/ubuntu/settings'
#@sudu = "sudo "

def print_message(message)
   puts message+"\n"
   system('logger '+message+"\n") 
end 

def tailor(fn, public_dns)
   if File.exists?(fn) 
      f = File.open(fn, "r")
      text = f.read
      f.close
      if text != nil and text != ""
         if public_dns != nil and public_dns != ""
            text = text.gsub("<endpoint>",public_dns)
         end
         File.open(fn, 'w') do |f|  
            f.write(text)
            f.close
         end
         print_message("{#fn} updated to #{public_dns}")
      end
   end
end 

print_message("config_listener.rb - Configure Oracle hostname")

# look for command line arguments
args = Array.new
i = 0
ARGV.each do|a|
  args[i]=a
  i+1
end
# add the oraclehome parameter if commandline parameter specified  
if args[0] != nil and args[0] != ""
   args[0]="oraclehome=#{args[0]}"
end   
  
# sleep 5 secs to make sure public_dns set  
sleep 5

url = 'http://169.254.169.254/latest/meta-data/instance-id'
@instance_id = Net::HTTP.get_response(URI.parse(url)).body

url = 'http://169.254.169.254/latest/meta-data/public-hostname'
public_dns = Net::HTTP.get_response(URI.parse(url)).body
# default amazon access settings
options = {}
options['accesskey'] = Settings.AMAZON_PUBLIC_KEY
options['secretaccesskey'] = Settings.AMAZON_PRIVATE_KEY
options['region'] = Settings.REGION

#
# switch between the following lines to get parameters from user data or 
# uncomment the lines to hardcode the parameters 
#
url_user_data = 'http://169.254.169.254/latest/user-data'
user_data = ""
if args[0]==nil or args[0]==""
   user_data = Net::HTTP.get_response(URI.parse(url_user_data)).body
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

#ec2 = RightAws::Ec2.new(options['accesskey'], options['secretaccesskey'],:endpoint_url => options['region'])
# get public_dns 
#public_dns = ""
#ec2.describe_instances([@instance_id]).each do |r|
#   public_dns = r[:dns_name]
#end


print_message("export ORACLE_HOME=#{options['oraclehome']}")
system "export ORACLE_HOME=#{options['oraclehome']}"

# taillor oracle user profile 
fn = "/home/oracle/.bash_profile"
print_message("Changing host in #{fn} to #{public_dns}")
tailor(fn, public_dns)

# tailor listener.ora
print_message("lsnrctl stop") 
system "lsnrctl stop" 

fn = "#{options['oraclehome']}/network/admin/listener.ora"
print_message("Changing host in listener.ora to #{public_dns}")
tailor(fn, public_dns)

print_message("lsnrctl start")
system "lsnrctl start"

