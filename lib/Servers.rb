require 'json'

class Servers

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/servers_config.json")
    @config = JSON.parse(data)
  end

  def api
    ''
  end

  def name
    ''
  end

  def config
    @config
  end

  def conn(type)
    nil
  end

  def reset_connection
    @conn = {}
  end
end

