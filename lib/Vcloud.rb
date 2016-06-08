#require 'fog'
require 'json'
require 'Vcloud_conn'

class Vcloud

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/vcloud_config.json")
    @config = JSON.parse(data)
  end

  def api
    'vcloud'
  end

  def name
    'vcloud'
  end

  def config
    @config
  end

  def conn(type)
    Fog.mock!
    if @conn[type] == nil
      begin
        case type
        when 'Compute'
          @conn[type] = Vcloud_conn.new(Fog::Compute::VcloudDirector.new(
            :vcloud_director_username => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'),
            :vcloud_director_password => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'),
            :vcloud_director_host => $ec2_main.settings.get('EC2_URL'),
            # need to add organization
            :vcloud_director_show_progress => false, # task progress bar on/off
          ))
        else
          nil
        end
      rescue
        reset_connection
        puts "ERROR: on #{type} connection to vcloud #{$!}"
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


