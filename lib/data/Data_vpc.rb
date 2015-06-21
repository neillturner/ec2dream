require 'rubygems'
require 'net/http'
require 'resolv'
require 'fog'

class Data_vpc

  def initialize(owner)
    puts "Data_vpc.initialize"
    @ec2_main = owner
  end


  def describe_vpcs(options = {})
    data = []
    if @ec2_main.settings.google
      conn = @ec2_main.environment.connection
      if conn != nil
        begin
          response = conn.list_networks
          if response.status == 200
            x = response.body['items']
            x.each do |r|
              r['vpcId'] = r['name']
              data.push(r)
            end
          else
            data = []
          end
        rescue
          puts "ERROR: getting all zones  #{$!}"
        end
      else
        raise "Connection Error"
      end
    else
      conn = @ec2_main.environment.connection
      if conn != nil
        begin
          response = conn.describe_vpcs(options = {})
          if response.status == 200
            data = response.body['vpcSet']
          else
            data = []
          end
        rescue
          puts "ERROR: describe_vpc #{$!}"
        end
      end
    end
    return data
  end
  def describe_subnets(options = {})
    data = []
    conn = @ec2_main.environment.connection
    if conn != nil
      begin
        response = conn.describe_subnets(options = {})
        if response.status == 200
          data = response.body['subnetSet']
        else
          data = []
        end
      rescue
        puts "ERROR: describe_subnet #{$!}"
      end
    end
    return data
  end
    # Delete a google network
  def  delete_network(name)
    data = false
    conn = @ec2_main.environment.connection
    if conn != nil
      response = conn.delete_network(name)
      if response.status == 200
        data = response.body
      else
        data = {}
      end
    else
      raise "Connection Error"
    end
    return data
  end
    # Insert a google network
  def  insert_network(name, ip_range)
    data = false
    conn = @ec2_main.environment.connection
    if conn != nil
      response = conn.insert_network(name, ip_range)
      if response.status == 200
        data = response.body
      else
        data = {}
      end
    else
      raise "Connection Error"
    end
    return data
  end
end