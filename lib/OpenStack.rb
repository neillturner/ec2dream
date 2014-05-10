require 'fog'
require 'json'

class OpenStack

def initialize()
  @conn = {}
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/openstack_config.json")
  @config = JSON.parse(data)
end

def api
   'openstack'
end

def name
   'openstack'
end

def config
 @config
end

def conn(type)
  #Fog.mock!
  if @conn[type] == nil
    begin
     case type
      when 'Image'
	@conn[type] = Fog::Image.new({:provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
      when 'Volume'
        @conn[type] = Fog::Volume.new({:provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
      when 'Compute'
         @conn[type] = Fog::Compute.new({:provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
      else
        nil
     end
    rescue
       reset_connection
       puts "ERROR: on #{type} connection to openstack #{$!}"
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