require 'fog'
require 'fog/azure/compute'
require 'json'

class Azure

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/azure_config.json")
    @config = JSON.parse(data)
  end

  def api
    'Azure'
  end

  def name
    'Azure'
  end

  def config
    @config
  end

  def conn(type)
    #Fog.mock!
    if @conn[type] == nil
      begin
        puts "Connecting to Azure #{type} Cloud at url #{$ec2_main.settings.get('EC2_URL')}"
        case type
        when 'Compute'
          @conn[type] = Fog::Compute.new(:provider => 'Azure', :azure_pem  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :azure_sub_id =>  $ec2_main.settings.get('AMAZON_ACCOUNT_ID'), :azure_api_url   => $ec2_main.settings.get('EC2_URL'))
        else
          nil
        end
      rescue
        puts "conn object #{@conn[type]}"
        reset_connection
        puts "ERROR: on #{type} connection to azure #{$!}"
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
