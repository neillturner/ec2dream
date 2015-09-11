require 'fog'
require 'json'

class Softlayer

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/softlayer_config.json")
    @config = JSON.parse(data)
  end

  def api
    'softlayer'
  end

  def name
    'softlayer'
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
          @conn[type] = Fog::Image.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Volume'
          puts "*** Volume"
          @conn[type] = Fog::Volume.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Compute'
          puts "***Compute"
          @conn[type] = Fog::Compute.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Network'
          puts "***Network"
          @conn[type] = Fog::Network.new({:connection_options => {:ssl_verify_peer => false}, :provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        else
          puts "***Nil"
          nil
        end
      rescue
        reset_connection
        puts "ERROR: on #{type} connection to softlayer #{$!}"
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

