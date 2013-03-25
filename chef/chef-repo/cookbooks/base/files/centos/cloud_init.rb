#!/usr/bin/ruby
#
# Script to perform various functions at startup or when run via a parameter
#
# script will auto mount ebs at startup
# 
# if you don't specify the device and dir it will just attach the EBS and and not mount it. Usefully when first initializing an EBS
#
# user_data or parameter on script contains parameters separated by &. e.g. vol=xxx&device=xxx&dir=xxx&accesskey=xxx&secretaccesskey=xxx&elasticip=xxxxxxxx
#
# Parameters
#
# accesskey        - Amazon Access Key. If not specified gets it from the Settings.rb
# secretaccesskey  - Amazon Secret Access Key. If not specified gets it from the Settings.rb
#
# Up to 5 EBS Disks
# 
# vol              - volume of ebs to attach
# dir              - directory where volume is to me mounted
# device           - device where vol is to be attached
# init_ebs         - specify Y to initialize the ebs (be careful with this option it will wipe existing data on ebs)
# format           - optional parmeter to specify file system format when init_ebs set to Y. Default is "ext3"
#
# vol2             - second volume of ebs to attach
# dir2             - second directory where volume is to me mounted
# device2          - second device where vol is to be attached
# init_ebs2        - specify Y to initialize the second ebs (be careful with this option it will wipe existing data on ebs)
# format2          - optional parmeter to specify file system format when init_ebs2 set to Y. Default is "ext3"
#
# vol5             - fifth volume of ebs to attach
# dir5             - fifth directory where volume is to me mounted
# device5          - fifth device where vol is to be attached
# init_ebs5        - specify Y to initialize the fifth ebs (be careful with this option it will wipe existing data on ebs)
# format5          - optional parmeter to specify file system format when init_ebs5 set to Y. Default is "ext3"
#
# elasticip        - specify elastic ip for instance
# resize_ebs       - specify Y to resize device specified by device parameter to resize 
# generate_hosts   - specify to add known addresses of known severs to /etc/hosts file
# hosts_tag        - tag name for hostname identification on instance (default is name)
# chef_run_list    - run list to pass to chef to configure server 
#                    example: role[base],recipe[server]
# chef_json        - json file to chef to configure server 
#                    example: { "run_list": [ "role[base]", "recipe[ops_master]" ] }
# chef_solo_run_list - run list to pass to chef solo to configure server 
#                    example: role[base],recipe[server]
# chef_solo_json     - json file to chef solo to configure server 
#                    example: { "run_list": [ "role[base]", "recipe[ops_master]" ] }
# signal           - specify Y to signal to cloudformation that application has completed configuration
#                    NOTE: In the UserData the SignalURL= parameter must be last parameter 
#
# For ubuntu add this script to etc/rc.local to automate the attach of EBS.
#       ruby /home/ubuntu/cloud_init.rb
# For redhat/centos add this script to etc/rc.local to automate the attach of EBS.
#       ruby /root/cloud_init.rb
#
# If you want to create an EBS from a snapshot you can do this on the create_instances amazon command 
#

require 'rubygems'
require 'right_aws'
require 'net/http'
# for redhat, centos
require '/root/settings'
@sudo = ""
# for ubuntu
#require '/home/ubuntu/settings'
#@sudo = "sudo "


def print_message(message)
   puts message+"\n"
   system('logger '+message+"\n") 
end 

def init_ebs(device, format)
  if format == nil or format == ""
     format = "ext3"
  end
  if device == nil or device == ""
     print_message("*** No device specified for initializing ebs ***")
  else 
     print_message("#{@sudo} echo y | #{@sudo} mkfs -t #{format} #{device}")
     system "#{@sudo} echo y | #{@sudo} mkfs -t #{format} #{device}"
     print_message("#{@sudo} tune2fs -m0 #{device}")
     system "#{@sudo} tune2fs -m0 #{device}"
  end 
end  

def resize_ebs(device)
  if device == nil or device == ""
     print_message("*** No device specified for resizing ebs ***")
  else    
     print_message("#{@sudo} df -h")
     system "#{@sudo} df -h"
     print_message("#{@sudo} resize2fs #{device}")
     system "#{@sudo} resize2fs #{device}"
     print_message("#{@sudo} df -h")
     system "#{@sudo} df -h"
  end   
end 

def process_ebs(ec2, vol, device, dir, init_ebs, format)
  if dir != nil and dir != ""
     print_message("Auto Attaching #{vol}")
  else
     print_message("Auto Attaching and Mounting #{vol}")
  end
  if vol == nil or vol == ""
    print_message('*** No EBS specified to attach ***')
  else 
    if device == nil or device == ""
      print_message('*** No EBS Device specified ***')
    else
      print_message("attach #{vol}")
      begin 
         result = ec2.attach_volume(vol, @instance_id, device)
         print_message("attach result #{result}")
      rescue 
         print_message("vol #{vol} did not attach")
         return
      end 
  
      # It can take a few seconds for the volume to become ready.
      # This is just to make sure it is ready before mounting it.
      # sleep for up to 1 minutes waiting for it to be attached 

      aws_attachment_status = ""
      max_sleep = 60
      current_sleep = 0
      while (aws_attachment_status != "attached") and (current_sleep<max_sleep) 
         sleep 5
         current_sleep = current_sleep + 5 
         ec2.describe_volumes().each do |s|
            if s[:aws_id] == vol
               aws_attachment_status = s[:aws_attachment_status]
            end   
         end
      end   
      if aws_attachment_status == "attached"
         if device != nil and device != ""
           if init_ebs == "y"
             init_ebs(device, format)
           end
         end  
         if dir != nil and dir != ""
            print_message("#{@sudo} vol #{vol} attached")
            print_message("#{@sudo} mount #{device} #{dir}")
            system("#{@sudo} mkdir #{dir}")
            system("#{@sudo} mount #{device} #{dir}")
         end
      else 
        print_message("vol #{vol} did not attach after waiting for 60 secs")
      end
    end
  end
end 

#
# generate hosts files in the following order 
# 1. running instances  tag called name set to nbame of instance
# 2. running instance security group name  
#
# NOTE:  This script can be run via cron to do regular updating of hosts file
#
def generate_hosts_file(ec2, server_tag)
   if server_tag == nil 
      server_tag = "name"
   end 
   hosts_file = File.open("/etc/hosts")
   File.open("/etc/hosts.bak", "w") {|f| f.write hosts_file }
   i = 0
   host_file_updated = false
   host_lines  = Array.new
   hosts_file.each do |line|
      host_lines[i] = line
      i=i+1 
   end
   server_name = ""
   ec2.describe_instances.each do |r|
      if r[:aws_state] == "running"
         server_name = r[:groups][0][:group_name]
         r[:tags].each do |k,v|
           if k == server_tag 
              server_name = v 
           end 
         end 
         private_ip_address = r[:private_ip_address]
         puts "ip address #{private_ip_address} server #{server_name}" 
         host_found = false
         host_lines.each_index do |l|
            if host_lines[l] != nil and host_lines[l] != ""
               a = host_lines[l].split(" ")
               if a.length > 0 and a[1] ==  server_name
                 if a[0] != nil and a[0] != "" and a[0] != private_ip_address
                   if a[0].length >= 7
                      a[0] = private_ip_address
                      host_lines[l] = ""
                      host_file_updated = true
                      host_found = true  
                      a.each do |d|
                         host_lines[l] = "#{host_lines[l]} #{d}"
                      end
                      print_message(" updated host #{host_lines[l]}") 
                   end
                 else
                    if a[0] != nil and a[0] != "" and a[0] == private_ip_address   
                       host_found = true
                    end
                 end
               end
            end
         end    
         if !host_found
            print_message("adding host #{private_ip_address} #{server_name}")   
            host_lines[host_lines.length+1] = "#{private_ip_address} #{server_name}"
            host_file_updated = true
         end
      end   
   end    
   if host_file_updated
      File.open("/etc/hosts", "w") do |f|
        host_lines.each do |l| 
           if l != nil
              f.puts(l)
           end
        end   
      end
   end     
end

#
#
# signal application configuratiomn complete to cloud formation
# NOTE: SignalURL must have been set in the userdata and it must be the last parameter 
#
#
def signal_application_configured(url_user_data)
   opts = {}
   instance_user_data = Net::HTTP.get_response(URI.parse(url_user_data)).body
   if instance_user_data.index("<title>404 - Not Found</title>") != nil
      print_message("no instance user data")
   else
      i = instance_user_data.index('SignalURL=')
      if i != nil and i < instance_user_data.length-10
         url = instance_user_data[i+10,instance_user_data.length]
         print_message("Application signaling configuration completed")
         data = '{"Status" : "SUCCESS","Reason" : "Configuration Complete","UniqueId" : "ID1234","Data" : "Application has completed configuration."}'
         puts(@sudo+ " curl -X PUT -H \'Content-Type:\' --data-binary \'"+data+'\' "'+url+'"') 
         system(@sudo+ " curl -X PUT -H \'Content-Type:\' --data-binary \'"+data+'\' "'+url+'"')       
      else 
         print_message("no SignalURL parameter in instance user data")
      end 
   end
end 

#
#
# Generate a json configure file for the runlist and run chef_client to configure node
# runlist is comma delimited list of roles and recipes.   
#
#

def run_chef_client(run_list, solo=false)
   chef = "chef-client"
   if solo
     chef = "chef-solo" 
   end
   print_message("running #{chef} run list #{run_list}")
   doc = ""
   run_list.split(',').each do |item|
      if doc != ""
         doc = doc +","
      end  
      doc = doc+" \""+item+"\""
   end
   doc = "{ \"run_list\": [ #{doc} ] }"
   File.open("/etc/chef/cloud_init.json", 'w') {|f| f.write(doc) }
   system(@sudo+ "mkdir /var/log/chef")
   print_message("#{chef} messages at /var/log/chef/messages")   
   print_message("#{chef} jsonfile: cloud_init.json")
   system(@sudo+ "#{chef} -j /etc/chef/cloud_init.json -L /var/log/chef/messages")
   print_message("#{chef} finished")
end 

#
#
# run chef_client to configure node with a passed json file 
#
#

def run_chef_client_json(json_string, solo=false)
   chef = "chef-client"
   if solo
      chef = "chef-solo" 
   end
   print_message("running #{chef} with json file #{json_string}")
   File.open("/etc/chef/cloud_init.json", 'w') {|f| f.write(json_string) }
   system(@sudo+ "mkdir /var/log/chef")
   print_message("#{chef} messages at /var/log/chef/messages")
   print_message("#{chef} jsonfile: cloud_init.json")    
   system(@sudo+ "#{chef} -j /etc/chef/cloud_init.json -L /var/log/chef/messages")
   print_message("#{chef} finished")  
end

print_message("cloud_int.rb - Initialise Cloud Settings")

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
# get parameters from user data  
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
# options['vol'] = 'vol-xxxxx'
# options['device'] = '/dev/sdf'
# options['dir'] = '/mnt/data01'


ec2 = RightAws::Ec2.new(options['accesskey'], options['secretaccesskey'],:endpoint_url => options['region'])

if options['vol'] != nil and options['vol'] != ""
   process_ebs(ec2, options['vol'], options['device'], options['dir'], options['init_ebs'], options['format'])
end

if options['resize_ebs'] != nil and options['resize_ebs'].downcase == 'y'
   resize_ebs(options['device'])
end   

if options['vol2'] != nil and options['vol2'] != ""
   process_ebs(ec2, options['vol2'], options['device2'], options['dir2'], options['init_ebs2'], options['format2'])
end  

if options['vol3'] != nil and options['vol3'] != ""
   process_ebs(ec2, options['vol3'], options['device3'], options['dir3'], options['init_ebs3'], options['format3'])
end  

if options['vol4'] != nil and options['vol4'] != ""
   process_ebs(ec2, options['vol4'], options['device4'], options['dir4'], options['init_ebs4'], options['format4'])
end  

if options['vol5'] != nil and options['vol5'] != ""
   process_ebs(ec2, options['vol5'], options['device5'], options['dir5'], options['init_ebs5'], options['format5'])
end  


#
# generate hosts file  
#

if options['generate_hosts'] != nil and options['generate_hosts'].downcase == 'y'
   generate_hosts_file(ec2, options['hosts_tag'])
end   

#
# signal application configuration complete to cloud formation   
#

if options['signal'] != nil and options['signal'].downcase == 'y'
   signal_application_configured(url_user_data)
end   


  
#
# associate elastic ip 
#
if options['elasticip'] != nil and options['elasticip'] != ""
   elasticip_available = false
   elasticip_inuse = false 
   begin
      ec2.describe_addresses({:public_ip=> options['elasticip']}).each do |r|
        if r[:@instance_id] == nil
           elasticip_available = true
        else 
           elasticip_inuse = true 
        end  
      end
   rescue 
      print_message("Error describing Elastic IP Addresses")
   end 
   if elasticip_inuse
      print_message("*** Elastic IP #{options['elasticip']} inuse ***")
   else 
      if !elasticip_available
         print_message("*** Elastic IP #{options['elasticip']} not found ***")        
      else
         begin 
           r = ec2.associate_address(@instance_id, {:public_ip=> options['elasticip']})
           print_message("Asociate Elastic IP #{options['elasticip']} succeeded")
         rescue
           print_message("Asociate Elastic IP #{options['elasticip']} failed")
         end  
      end
   end  
end

#
# run chef client against passed run list or json file   
#

if options['chef_run_list'] != nil and options['chef_run_list'] != ""
   run_chef_client(options['chef_run_list'])
end 

if options['chef_json'] != nil and options['chef_json'] != ""
   run_chef_client_json(options['chef_json'])
end 

if options['chef_solo_run_list'] != nil and options['chef_solo_run_list'] != ""
   run_chef_client(options['chef_solo_run_list'],true)
end 

if options['chef_solo_json'] != nil and options['chef_solo_json'] != ""
   run_chef_client_json(options['chef_solo_json'],true)
end 

