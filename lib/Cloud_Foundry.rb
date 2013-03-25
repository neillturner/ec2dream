require 'cloudfoundry'

class Cloud_Foundry 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/cloud_foundry_config.json")
  @config = JSON.parse(data)
end

def api 
   'cloudfoundry'
end

def name 
   'cloudfoundry'
end   

def config
 @config
end

def conn(type) 
  #Fog.mock!
  if @conn[type] == nil
     begin
       @conn[type] = CloudFoundry::Client.new({:target_url => $ec2_main.settings.get('EC2_URL')})
       @conn[type].login($ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'))         	
       @conn[type]
	rescue
       reset_connection
       puts "***Error on #{type} connection to cloudfoundry #{$!}"
       puts "check your keys in environment"
	   nil
    end  	
  else
    @conn[type]
  end
end 

def reset_connection 
   @conn = {} 
end


end