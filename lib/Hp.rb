require 'fog'

class Hp 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/hp_config.json")
  @config = JSON.parse(data)
end

def api 
   'openstack'
end

def name 
   'hp'
end   

def config
 @config
end

def conn(type) 
  #Fog.mock!
  if @conn[type] == nil
    begin
     puts "Connecting to HP Cloud #{type} at url #{$ec2_main.settings.get('EC2_URL')}"	
     case type
      when 'Image' 
		@conn[type] = Fog::Image.new({:provider => "HP",:hp_access_key  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :hp_secret_key =>  $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :hp_auth_uri   => $ec2_main.settings.get('EC2_URL'), :hp_tenant_id => $ec2_main.settings.get('AMAZON_ACCOUNT_ID'), :hp_avl_zone => $ec2_main.settings.get('AVAILABILITY_ZONE')}) 
      when 'BlockStorage' 
        @conn[type] =  Fog::HP::BlockStorage.new(:hp_access_key  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :hp_secret_key =>  $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :hp_auth_uri   => $ec2_main.settings.get('EC2_URL'), :hp_tenant_id => $ec2_main.settings.get('AMAZON_ACCOUNT_ID'), :hp_avl_zone => $ec2_main.settings.get('AVAILABILITY_ZONE')) 
       # @conn[type] = Fog::BlockStorage.new({:provider => "HP",:hp_access_key  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :hp_secret_key =>  $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :hp_auth_uri   => $ec2_main.settings.get('EC2_URL'), :hp_tenant_id => $ec2_main.settings.get('AMAZON_ACCOUNT_ID'), :hp_avl_zone => $ec2_main.settings.get('AVAILABILITY_ZONE')}) 
	  when 'Compute'
         @conn[type] = Fog::Compute.new({:provider => "HP",:hp_access_key  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :hp_secret_key =>  $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :hp_auth_uri   => $ec2_main.settings.get('EC2_URL'), :hp_tenant_id => $ec2_main.settings.get('AMAZON_ACCOUNT_ID'), :hp_avl_zone => $ec2_main.settings.get('AVAILABILITY_ZONE')}) 
 	  else 
        nil
     end
    rescue
       reset_connection
       puts "***Error on #{type} connection to hp #{$!}"
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