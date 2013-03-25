require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_availability_zones

  def initialize(owner)
     puts "Data_availablity_zones.initialize"
     @ec2_main = owner  
  end 

  # Describes availability zones that are currently available to the account and their states.
  #
  # Returns an array of 3 keys (:region_name, :zone_name and :zone_state) hashes:
  #
  #  ec2.describe_availability_zones  #=> [{:region_name=>"us-east-1",
  #                                         :zone_name=>"us-east-1a",
  #                                         :zone_state=>"available"}, ... ]
  #
  def all(platform="")
      data = []
      if  @ec2_main.settings.openstack_hp or platform == "openstack_hp"
          data.push({:zone_name => 'az-1.region-a.geo-1'})
          data.push({:zone_name => 'az-2.region-a.geo-1'})
          data.push({:zone_name => 'az-3.region-a.geo-1'})
      elsif  @ec2_main.settings.openstack
           data.push({:zone_name => 'default'})      
      else
          conn = @ec2_main.environment.connection
          if conn != nil
             begin 
               if ((conn.class).to_s).start_with? "Fog::Compute::AWS"
                  x = conn.describe_availability_zones
	          x = x.body['availabilityZoneInfo']
                  x.each do |y|
                     r = {}
                     r[:region_name] = y['regionName']
                     r[:zone_name]  = y['zoneName']
                     r[:zone_state] =  y['zoneState']
                     data.push(r)
                  end
               else
                  data = conn.describe_availability_zones
               end 
             rescue
               puts "**Error getting all availablity zones  #{$!}"
             end
          end   
      end   
      return data
  end
  
end