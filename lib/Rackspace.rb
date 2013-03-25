require 'fog'

class Rackspace 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/rackspace_config.json")
  @config = JSON.parse(data)
end

def api 
   'openstack'
end

def name 
   'rackspace'
end   

def config
 @config
end

def conn(type) 
   #Fog.mock!
   auth_url = "https://identity.api.rackspacecloud.com"
   vol_url = "https://blockstorage.api.rackspacecloud.com/v1"
   ec2_url =  $ec2_main.settings.get('EC2_URL')
   if ec2_url != nil and ec2_url !=""
      region = ""
      sa = (ec2_url).split"."
	  if sa.size>1
	     region = (sa[0])
      end
      if region.downcase == "https://lon" 
          auth_url = "https://lon.identity.api.rackspacecloud.com"
		  vol_url = "https://lon.blockstorage.api.rackspacecloud.com/v1"
      end    
    end	  
   if @conn[type] == nil
    begin	 
     case type
      when 'BlockStorage' 
        @conn[type] = Fog::Rackspace::BlockStorage.new(:rackspace_username  =>  $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :rackspace_api_key =>   $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :rackspace_auth_url   => auth_url, :rackspace_endpoint => vol_url)
	  when 'Compute'
         @conn[type] = Fog::Compute.new({:provider => "Rackspace", :rackspace_username  =>  $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :rackspace_api_key =>   $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :rackspace_auth_url   => auth_url, :rackspace_endpoint => ec2_url, :version => :v2 })
      else 
        nil
     end
    rescue
       reset_connection
       puts "***Error on #{type} connection to rackspace #{$!}"
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