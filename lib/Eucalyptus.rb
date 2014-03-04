require 'fog'
require 'json'

class Eucalyptus 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/eucalyptus_config.json")
  @config = JSON.parse(data)
end

def api 
   'aws'
end

def name 
   'eucalyptus'
end   

def config
 @config
end

def conn(type) 
  #Fog.mock!
  if @conn[type] == nil
    region = "eucalyptus"
    begin	 
       case type 
 	 when 'Compute'
             @conn[type] = Fog::Compute.new(:provider=>'AWS',:aws_access_key_id =>  $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :endpoint => $ec2_main.settings.get('EC2_URL'), :region => region) # , :version => "2010-08-31")
         else
            nil
       end
    rescue
       reset_connection
       puts "ERROR: on #{type} connection to eucalyptus #{$!}"
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