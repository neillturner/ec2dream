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
  
 end 