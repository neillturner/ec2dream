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
          puts "*** Image"
          @conn[type] = Fog::Image.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
        when 'Volume'
          puts "*** Volume"
          @conn[type] = Fog::Volume.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
        when 'Compute'
          puts "***Compute"
          @conn[type] = Fog::Compute.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
        when 'Orchestration'
          puts "***Orchestration"
          @conn[type] = Fog::Orchestration.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'OpenStack', :openstack_auth_url => $ec2_main.settings.get('EC2_URL'), :openstack_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :openstack_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :openstack_tenant   => $ec2_main.settings.get("AMAZON_ACCOUNT_ID")})
        else
          puts "***Nil"
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

