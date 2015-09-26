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
          @conn[type] = Fog::Image.new({:provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Volume'
          @conn[type] = Fog::Volume.new({:provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Compute'
          @conn[type] = Fog::Compute.new({:provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        when 'Network'
          @conn[type] = Fog::Network.new({:provider => 'softlayer', :softlayer_api_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :softlayer_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')})
        else
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

