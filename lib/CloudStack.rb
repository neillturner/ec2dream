require 'fog'
require 'json'

class CloudStack 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/cloudstack_config.json")
  @config = JSON.parse(data)
  # set AWS API version for version of cloudstack  
  @version = "2012-08-15"  # cloudstack 4.1
  #@version = "2010-11-15"  # cloudstack 4.0
end

def api 
   'aws'
end

def name 
   'cloudstack'
end   

def config
 @config
end

def conn(type) 
  #Fog.mock!
  if @conn[type] == nil
    begin	 
       case type 
 	 when 'Compute'
             @conn[type] = Fog::Compute.new(:provider=>'AWS',:aws_access_key_id =>  $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :endpoint => $ec2_main.settings.get('EC2_URL'), :version => @version)
         else
            nil
       end
    rescue
       reset_connection
       puts "ERROR: on #{type} connection to cloudstack #{$!}"
       puts "check your keys in environment"
    end  	
  else
    @conn[type]
  end
end 

def reset_connection 
   @conn = {} 
end

end